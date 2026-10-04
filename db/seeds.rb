# frozen_string_literal: false
#
# Demo seed data — enough for the application to render every core page and
# exercise the main flows locally (see README "Running locally").
#
# Idempotent: safe to run repeatedly (bin/rails db:seed).

puts "Seeding demo data..."

def quietly(label)
  yield
  puts "  ok: #{label}"
rescue StandardError => e
  puts "  skip: #{label} (#{e.class}: #{e.message.to_s[0..120]})"
end

# ---------------------------------------------------------------------------
# Color scheme + government (the app's root singleton)
# ---------------------------------------------------------------------------
gov = Government.first

unless gov
  scheme = ColorScheme.create!(name: 'Default')
  gov = Government.new(
    status: 'active',
    name: 'The White House 2',
    short_name: 'wh2',
    domain_name: 'localhost',
    layout: 'wh2',
    tagline: 'Together we decide what the government should do.',
    target: 'the government',
    email: 'info@example.gov',
    is_public: true,
    is_tags: true,
    is_facebook: false,
    is_legislators: false,
    is_twitter: false,
    admin_name: 'White House 2 Admin',
    admin_email: 'admin@example.gov',
    briefing_name: 'Briefing',
    tags_name: 'Issues',
    currency_name: 'Capitol',
    currency_short_name: 'Cc',
    homepage: 'index',
    mission: 'This is where we decide together what the government should do.',
    prompt: 'What should the government do better?',
    language_code: 'en',
    color_scheme_id: scheme.id,
    is_suppress_empty_priorities: false
  )
  gov.save(validate: false)
  puts "  ok: government ##{gov.id}"
end

gov = Government.first
if gov && gov.homepage != 'index'
  gov.update_column(:homepage, 'index')
  puts "  ok: homepage set to index"
end
Government.current = gov
Thread.current[:government] = gov

# Apply the WhiteHouse 3 palette to the demo color scheme (see
# app/models/wh3_theme.rb + docs/wh3-concept/). Idempotent.
if gov && gov.color_scheme
  Wh3Theme.apply!(gov.color_scheme)
  puts "  ok: WH3 palette applied to color scheme ##{gov.color_scheme_id}"
end

# ---------------------------------------------------------------------------
# Users  (all demo accounts use password: password123)
# ---------------------------------------------------------------------------
def seed_user(attrs, password: 'password123')
  existing = User.find_by_email(attrs[:email])
  return existing if existing

  u = User.new(attrs)
  u.password = password
  u.save(validate: false)
  u
end

admin = seed_user({
  login: 'admin', email: 'admin@example.gov',
  first_name: 'Ada', last_name: 'Admin',
  status: 'active', activated_at: Time.now.utc,
  is_admin: true, is_branch_chosen: true
})
puts "  ok: admin user ##{admin.id}"

members = [
  { login: 'jordan', email: 'jordan@example.com', first_name: 'Jordan', last_name: 'Rivera' },
  { login: 'sam', email: 'sam@example.com', first_name: 'Sam', last_name: 'Chen' },
  { login: 'riley', email: 'riley@example.com', first_name: 'Riley', last_name: 'Okafor' },
  { login: 'casey', email: 'casey@example.com', first_name: 'Casey', last_name: 'Nguyen' },
  { login: 'morgan', email: 'morgan@example.com', first_name: 'Morgan', last_name: 'Ellis' },
  { login: 'taylor', email: 'taylor@example.com', first_name: 'Taylor', last_name: 'Brooks' }
].map do |attrs|
  seed_user(attrs.merge(status: 'active', activated_at: Time.now.utc, is_branch_chosen: true))
end

if gov.official_user_id.nil?
  gov.update_columns(official_user_id: admin.id, official_user_short_name: admin.login)
end

# ---------------------------------------------------------------------------
# Priorities
# ---------------------------------------------------------------------------
priority_names = [
  "End the war in Afghanistan responsibly",
  "Create a public option for health care",
  "Invest in high-speed rail",
  "Reform campaign finance",
  "Protect net neutrality",
  "Expand renewable energy tax credits",
  "Repeal the Defense of Marriage Act",
  "Improve veterans' health services",
  "Lower the cost of higher education",
  "Strengthen food safety inspections"
]

if Priority.count.zero?
  priority_names.each_with_index do |name, i|
    quietly("priority: #{name[0..40]}") do
      p = Priority.new(
        name: name,
        user_id: admin.id,
        status: 'published',
        published_at: Time.now.utc - (i * 6).hours,
        ip_address: '127.0.0.1'
      )
      p.save(validate: false)
    end
  end
end

# ---------------------------------------------------------------------------
# Endorsements — see "designed voting patterns" after the Issues section
# (the pattern votes on tagged priorities too, so it must run once all
# priorities exist).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Issues (tags). The homepage renders one block per issue (a Tag with
# priorities_count > 4) showing its top / rising / controversial priority,
# so give a few issues enough tagged priorities to qualify.
# ---------------------------------------------------------------------------
if Tag.count.zero?
  issue_seeds = {
    "Economy" => [
      "Create a national infrastructure bank",
      "Simplify the tax code",
      "Cap credit card interest rates",
      "Expand unemployment insurance",
      "Invest in high-speed rail"
    ],
    "Health Care" => [
      "Let Medicare negotiate drug prices",
      "Expand community health centers",
      "Fund rural telemedicine",
      "Strengthen pandemic surveillance",
      "Reduce emergency room wait times"
    ],
    "Energy" => [
      "Build a modern electric grid",
      "Extend the clean energy tax credit",
      "Raise fuel economy standards",
      "Weatherize low-income housing",
      "Fund next-generation nuclear research"
    ]
  }

  issue_seeds.each do |tag_name, names|
    names.each do |name|
      quietly("issue priority: #{name[0..40]}") do
        p = Priority.find_or_initialize_by(name: name)
        if p.new_record?
          p.assign_attributes(
            user_id: admin.id,
            status: 'published',
            published_at: Time.now.utc,
            ip_address: '127.0.0.1'
          )
          p.save(validate: false)
        end
        p.issue_list.add(tag_name)
        p.save(validate: false)
      end
    end

    quietly("issue: #{tag_name}") do
      tag = Tag.find_by_name(tag_name)
      next unless tag
      tag.update_counts
      tagged = tag.priorities.published.order(:id).to_a
      tag.top_priority_id = tagged[0]&.id
      tag.rising_priority_id = tagged[1]&.id
      tag.controversial_priority_id = tagged[2]&.id
      tag.save(validate: false)
    end
  end
end

# ---------------------------------------------------------------------------
# Endorsements — designed voting patterns for the WH3 common-ground demo.
#
# Six members form two blocs by voting pattern (see common_ground.rb; the
# detector splits on agreement, never on party). Bloc "left" = jordan, sam,
# casey; bloc "right" = riley, morgan, taylor. Every priority the homepage
# surfaces gets a designed agreement spread — 100 / 67 / 33 / 0 — the
# achievable shares for 3-member blocs. "Pattern" priorities (disjoint from
# the targets) carry the bloc signal the detector needs.
# Idempotent: demo members' votes are rebuilt from the pattern each run.
# ---------------------------------------------------------------------------
quietly("designed endorsement patterns for the common-ground demo") do
  left  = members.select { |u| %w[jordan sam casey].include?(u.login) }
  right = members.select { |u| %w[riley morgan taylor].include?(u.login) }

  # Targets: everything shown on the homepage or early browse pages.
  targets = []
  Tag.order(:id).each do |tag|
    targets << tag.top_priority_id << tag.rising_priority_id << tag.controversial_priority_id
  end
  targets += Priority.published.order(:id).limit(6).ids
  targets = targets.compact.uniq
  targets = Priority.where(id: targets).order(:id).ids

  # Disjoint pattern priorities carry the bloc split signal.
  pattern_ids = Priority.published.where.not(id: targets).order(:id).limit(12).ids

  demo_user_ids = members.map(&:id)
  Endorsement.where(user_id: demo_user_ids, priority_id: (targets + pattern_ids).uniq).delete_all

  # How many of each 3-member bloc endorses, per designed score.
  # 100: both blocs yes.  67: both blocs 2-of-3.  33: both blocs 1-of-3.
  # 0:   left loves it, right opposes it.
  design = {
    100 => { left: 3, right: 3 },
    67  => { left: 2, right: 2 },
    33  => { left: 1, right: 1 },
    0   => { left: 3, right: 0 }
  }

  buckets = design.keys.each_with_object({}) { |s, h| h[s] = [] }
  targets.each_with_index { |pid, i| buckets[design.keys[i % 4]] << pid }

  position = 0
  buckets.each do |score, pids|
    pids.each do |pid|
      position += 1
      { left => design[score][:left], right => design[score][:right] }.each do |bloc, yes_count|
        bloc.each_with_index do |u, idx|
          Endorsement.new(user_id: u.id, priority_id: pid, position: position,
                          value: idx < yes_count ? 1 : -1).save(validate: false)
        end
      end
    end
  end

  # Pattern: left +1 / right -1 on every pattern priority. Pure 0%/100%
  # agreement makes the most-disagreeing pair obvious to the detector.
  pattern_ids.each do |pid|
    left.each  { |u| Endorsement.new(user_id: u.id, priority_id: pid, position: 99, value: 1).save(validate: false) }
    right.each { |u| Endorsement.new(user_id: u.id, priority_id: pid, position: 99, value: -1).save(validate: false) }
  end

  # delete_all bypassed aasm's counters; recount from the rows.
  (targets + pattern_ids).uniq.each do |pid|
    up = Endorsement.active.where(priority_id: pid).endorsing.count
    down = Endorsement.active.where(priority_id: pid).opposing.count
    Priority.where(id: pid).update_all(
      "endorsements_count = #{up + down}, up_endorsements_count = #{up}, down_endorsements_count = #{down}")
  end
  puts "  ok: pattern votes across #{targets.size} targets + #{pattern_ids.size} pattern priorities"
end

# ---------------------------------------------------------------------------
# Points (pro/con arguments)
# ---------------------------------------------------------------------------
if Point.count.zero?
  point_specs = [
    ["It would save billions", "Independent analyses project over $100B in savings within a decade, money that could be reinvested at home.", 1],
    ["It creates jobs", "Domestic infrastructure spending has one of the highest employment multipliers of any federal outlay.", 1],
    ["It raises taxes on everyone", "Critics argue the funding mechanism falls hardest on middle-income households.", 0],
    ["It is long overdue", "Other developed nations have operated similar programs for decades with measurable success.", 1]
  ]

  point_specs.each_with_index do |(name, content, value), i|
    quietly("point: #{name}") do
      priority = Priority.order(:id)[i % [Priority.count, 1].max]
      pt = Point.new(
        name: name,
        content: content,
        priority_id: priority&.id,
        user_id: members[i % members.size].id,
        value: value,
        status: 'published',
        published_at: Time.now.utc - (i * 3).hours
      )
      pt.save(validate: false)
    end
  end
end

# ---------------------------------------------------------------------------
# WH3 common-ground scores (see app/models/common_ground.rb)
# ---------------------------------------------------------------------------
quietly("common-ground scores") do
  scores = CommonGround.recompute!
  scored = scores.values.count { |s| s > 0 }
  puts "  ok: #{scored} priorities with a common-ground score"
end

# ---------------------------------------------------------------------------
# Email templates (used by mailers / liquid rendering)
# ---------------------------------------------------------------------------
{
  'welcome' => ['Welcome to {{government.name}}',
                "Hi {{user.first_name}},\n\nWelcome to {{government.name}}! Add your priorities and endorse the ones you care about."],
  'invitation' => ['{{sender_name}} invited you to {{government.name}}',
                   "{{sender_name}} thought you should know about {{government.name}}.\n\nCome share what you think the government should do."],
  'finished' => ['{{priority.name}} is complete',
                 'A priority you endorsed has been completed.']
}.each do |name, (subject, content)|
  quietly("email template: #{name}") do
    EmailTemplate.find_or_create_by!(name: name) do |t|
      t.subject = subject
      t.content = content
    end
  end
end

puts "Seeding complete."
puts "  government: #{Government.first&.name}"
puts "  users: #{User.count}  priorities: #{Priority.count}  points: #{Point.count}  endorsements: #{Endorsement.count}"
puts "  logins: admin@example.gov / jordan@example.com / sam@example.com / riley@example.com — password: password123"
