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
  { login: 'riley', email: 'riley@example.com', first_name: 'Riley', last_name: 'Okafor' }
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
# Endorsements (members rank priorities)
# ---------------------------------------------------------------------------
if Endorsement.count.zero?
  Priority.order(:id).limit(6).each_with_index do |p, i|
    quietly("endorsement for priority ##{p.id}") do
      e = Endorsement.new(
        user_id: members[i % members.size].id,
        priority_id: p.id,
        position: i + 1,
        value: 1
      )
      e.save(validate: false)
    end
  end
end

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
