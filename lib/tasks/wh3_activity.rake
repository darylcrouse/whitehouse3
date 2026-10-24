# Give the demo priorities real activity so the derived fields mean something.
#
#   rails wh3:seed_activity        # write charts + balance a few votes
#   rails wh3:seed_activity DRY=1
#
# Why this exists: PriorityRanker derives trending_score from position_7days,
# which it reads from a PriorityChart row dated exactly seven days back, and
# derives is_controversial from the up/down endorsement ratio. A freshly seeded
# demo has neither, so every priority reads as flat-and-new, the "Rising" tab is
# empty, and PriorityRanker clears each Tag's rising/controversial pointers,
# leaving homepage issue blocks with one item instead of three.
#
# This writes the missing history instead of hand-setting the pointers, so a
# later ranker run recomputes the same answers instead of wiping them.
namespace :wh3 do
  desc "Seed 7/30-day position history and balanced votes for the demo"
  task seed_activity: :environment do
    dry = ENV["DRY"].present?

    # Ranker reads charts at (now - 5h - N days) so the date must match exactly.
    anchor = Time.now - 5.hours
    d7  = anchor - 7.days
    d30 = anchor - 30.days

    # Positions come from the ranker; without one run everything is 0.
    PriorityRanker.new.perform

    tags = Tag.order(:id).to_a
    risers = {}
    balanced = {}

    # The ranker sets each tag's top pointer from the current standings; the
    # rising pick has to be somebody else or the homepage block repeats a row.
    tags.each do |tag|
      tag.reload
      candidates = tag.priorities.published
                       .order(Arel.sql("endorsements_count desc, id asc"))
                       .to_a
                       .reject { |p| p.id == tag.top_priority_id }
      risers[tag.id] = candidates[0, 2]
      balanced[tag.id] = candidates[2] || candidates[1]
    end

    puts "7-day anchor: #{d7.strftime('%Y-%m-%d')}  30-day anchor: #{d30.strftime('%Y-%m-%d')}"
    risers.each do |tag_id, list|
      tag = tags.find { |t| t.id == tag_id }
      puts "tag #{tag.name}: rising=#{list.map(&:id).inspect} balanced=#{balanced[tag_id]&.id.inspect}"
    end

    if dry
      puts "\nDRY=1 — nothing written."
      next
    end

    # Rebuild rather than layer: a priority that stopped being a riser must not
    # keep yesterday's flattering history.
    [d7, d30].each do |date|
      PriorityChart.where(date_year: date.year, date_month: date.month,
                          date_day: date.day).delete_all
    end

    Priority.published.order(:id).each do |p|
      rank = risers.values.flatten.index(p)
      pos = p.position.to_i
      pos = 12 if pos <= 0

      # Change is (old_position - current_position): a numerically worse rank
      # seven days ago means the priority climbed since. Multipliers differ so
      # the tag's first riser outranks its second instead of tying.
      mult = rank.nil? ? 1 : (rank.zero? ? 3 : 2)
      old7  = [pos * mult, 25].min
      old30 = [pos * (mult + 1), 25].min

      [[d30, old30], [d7, old7]].each do |date, position|
        chart = PriorityChart.find_by(
          priority_id: p.id,
          date_year: date.year, date_month: date.month, date_day: date.day
        ) || PriorityChart.new(
          priority_id: p.id,
          date_year: date.year, date_month: date.month, date_day: date.day
        )
        chart.position = position
        chart.up_count = p.up_endorsements_count.to_i
        chart.down_count = p.down_endorsements_count.to_i
        chart.volume_count = p.endorsements_count.to_i
        chart.save(validate: false)
      end
    end

    # A priority only counts as controversial when 0.5 < up/down < 2, so a
    # three-member bloc's 2:1 or 1:2 never qualifies. Balance one priority per
    # issue at 3:3 so each block can show a genuinely contested item.
    balanced.each_value do |p|
      next unless p
      up = Endorsement.active.where(priority_id: p.id).endorsing.count
      down = Endorsement.active.where(priority_id: p.id).opposing.count
      target = [up, down].max
      add_up = target - up
      add_down = target - down
      next if add_up.zero? && add_down.zero?

      pool = User.where.not(id: p.user_id)
                 .where.not(id: Endorsement.where(priority_id: p.id).select(:user_id))
                 .order(:id).to_a
      add_up.times do
        u = pool.shift or break
        Endorsement.new(user_id: u.id, priority_id: p.id, position: 99,
                        value: 1, ip_address: "127.0.0.1").save(validate: false)
      end
      add_down.times do
        u = pool.shift or break
        Endorsement.new(user_id: u.id, priority_id: p.id, position: 99,
                        value: -1, ip_address: "127.0.0.1").save(validate: false)
      end
    end

    Endorsement.active.group(:priority_id).count.each do |pid, _|
      up = Endorsement.active.where(priority_id: pid).endorsing.count
      down = Endorsement.active.where(priority_id: pid).opposing.count
      Priority.where(id: pid).update_all(
        up_endorsements_count: up, down_endorsements_count: down,
        endorsements_count: up + down
      )
    end

    PriorityRanker.new.perform
    CommonGround.recompute!

    puts "\nafter:"
    Tag.order(:id).each do |t|
      t.reload
      puts "  #{t.name}: top=#{t.top_priority_id.inspect} rising=#{t.rising_priority_id.inspect} " \
           "controversial=#{t.controversial_priority_id.inspect}"
    end
    puts "  priorities trending up: #{Priority.published.rising.count}"
    puts "  controversial: #{Priority.published.controversial.count}"
    puts "\nrestart puma to drop the memoized caches."
  end
end
