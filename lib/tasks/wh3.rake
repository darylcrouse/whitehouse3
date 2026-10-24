# Demo content maintenance for The White House 3.
#
#   rails wh3:refresh_demo_priorities           # apply db/demo_priorities.rb
#   rails wh3:refresh_demo_priorities DRY=1     # show the mapping, change nothing
#
# Renames the existing demo priorities IN PLACE. Ids stay put, so the
# endorsements, points, notifications and the designed common-ground spread
# attached to those rows survive the refresh. A rebuild-from-scratch would
# orphan all of that, and the demo's whole point is the vote patterns.
namespace :wh3 do
  desc "Rename the demo priorities to the current db/demo_priorities.rb content"
  task refresh_demo_priorities: :environment do
    require Rails.root.join("db/demo_priorities").to_s

    dry = ENV["DRY"].present?
    slots = Wh3Demo::Priorities.slots

    general_slots = slots.select { |(_name, tag)| tag.nil? }
    issue_slots = slots.select { |(_name, tag)| tag.present? }
                            .group_by { |(_name, tag)| tag }
                            .transform_values { |list| list.map(&:first) }

    rows = Priority.published.order(:id).to_a
    untagged = rows.select { |p| p.cached_issue_list.blank? }
    by_tag = {}
    Tag.order(:id).each do |tag|
      by_tag[tag.name] = tag.priorities.published.order(:id).to_a
    end

    puts "published priorities: #{rows.size}"
    puts "untagged rows: #{untagged.size} (content has #{general_slots.size} general slots)"
    by_tag.each do |name, list|
      wanted = issue_slots[name]&.size || 0
      puts "tag #{name.inspect}: #{list.size} rows (content has #{wanted} slots)"
    end

    assignments = []
    general_slots.each_with_index do |(name, _tag), i|
      row = untagged[i]
      break unless row
      assignments << [row, name, nil]
    end

    issue_slots.each do |tag_name, names|
      (by_tag[tag_name] || []).each_with_index do |row, i|
        break unless names[i]
        assignments << [row, names[i], tag_name]
      end
    end

    if assignments.empty?
      puts "nothing to assign; run `rails db:seed` first"
      next
    end

    assignments.each do |row, new_name, tag_name|
      tag_note = tag_name ? "[#{tag_name}]" : "[general]"
      puts format("%3d %-11s %-58s <- %s", row.id, tag_note, new_name, row.name)

      next if dry

      # validate: false — the legacy model carries 2009-era validations that
      # check relationships we are not touching here.
      row.name = new_name
      row.cached_issue_list = tag_name.to_s
      row.save(validate: false)

      row.issue_list = tag_name ? [tag_name] : []
      row.save(validate: false)
    end

    if dry
      puts "\nDRY=1 — nothing written."
      next
    end

    Tag.order(:id).each do |tag|
      tag.update_counts
      tagged = tag.priorities.published.order(:id).to_a
      tag.update_columns(
        top_priority_id: tagged[0]&.id,
        rising_priority_id: tagged[1]&.id,
        controversial_priority_id: tagged[2]&.id
      )
    end

    # Ranks and the common-ground score are derived; recompute both so the
    # listings and badges agree with the new content.
    PriorityRanker.new.perform
    CommonGround.recompute!
    Rails.cache.clear

    dupes = Priority.published.group(:name).having("COUNT(*) > 1").count
    puts "\ndone. #{assignments.size} priorities renamed."
    puts "duplicate names: #{dupes.inspect}" if dupes.any?
    puts "restart puma to drop the memoized Government/priority caches."
  end
end
