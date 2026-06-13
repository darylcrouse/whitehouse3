# Seed data for the White House rebuild. Produces a realistic, clickable demo:
# a configured site, an official leader, members, ranked priorities with points,
# documents, comments and an activity feed.
#
# Idempotent: running it again won't duplicate the core records.

puts "Seeding #{Rails.env}…"

gov = Government.current
gov.update!(
  name: "White House",
  tagline: "A government of the people, by the people — decide what matters.",
  mission: "Let thousands of people set the nation's priorities together.",
  prompt: "What do you think the government should do?",
  is_tags: true,
  is_branches: true
)

PASSWORD = "password123"

def make_user(login, first, last, email, admin: false, bio: nil)
  User.find_or_create_by!(login: login) do |u|
    u.email_address = email
    u.first_name = first
    u.last_name = last
    u.password = PASSWORD
    u.password_confirmation = PASSWORD
    u.is_admin = admin
    u.bio = bio
    u.status = "active"
    u.score = rand(0.8..1.6).round(2)
  end
end

president = make_user("president", "Alex", "President", "president@example.gov",
                      admin: true, bio: "Serving as the official voice on this platform.")
gov.update!(official_user_id: president.id)

admin = make_user("admin", "Sam", "Admin", "admin@example.com", admin: true,
                  bio: "Site administrator.")

member_data = [
  ["jordan",  "Jordan",  "Lee",      "Lifelong civic nerd."],
  ["taylor",  "Taylor",  "Morgan",   "Teacher and union organizer."],
  ["casey",   "Casey",   "Rivera",   "Small business owner."],
  ["riley",   "Riley",   "Nguyen",   "Climate scientist."],
  ["morgan",  "Morgan",  "Patel",    "Healthcare worker."],
  ["devon",   "Devon",   "Brooks",   "Veteran and dad of three."],
  ["sky",     "Sky",     "Johnson",  "Student and first-time voter."],
  ["quinn",   "Quinn",   "Adams",    "Retired postal worker."]
]
members = member_data.map { |l, f, ln, bio| make_user(l, f, ln, "#{l}@example.com", bio: bio) }
everyone = [president, admin, *members]

branches = ["Northeast", "Midwest", "South", "West"].map do |name|
  Branch.find_or_create_by!(name: name) { |b| b.description = "Members from the #{name}." }
end
members.each_with_index { |u, i| u.update!(branch_id: branches[i % branches.size].id) }

# Tags
tag_names = %w[economy healthcare environment education energy jobs democracy
               immigration justice technology housing veterans]
tag_names.each do |t|
  Tag.find_or_create_by!(slug: t) { |tag| tag.name = t; tag.title = t.titleize }
end

priority_seeds = [
  ["Invest in renewable energy infrastructure",        %w[energy environment jobs]],
  ["Make community college tuition-free",              %w[education jobs]],
  ["Guarantee paid family and medical leave",          %w[healthcare jobs]],
  ["Expand high-speed rail between major cities",      %w[environment technology jobs]],
  ["Cap the price of insulin at $35 a month",          %w[healthcare]],
  ["Modernize the power grid for resilience",          %w[energy technology]],
  ["Forgive a portion of federal student loan debt",   %w[education economy]],
  ["Raise the federal minimum wage",                   %w[economy jobs]],
  ["Protect national parks from development",          %w[environment]],
  ["Fund universal pre-kindergarten",                  %w[education]],
  ["Rebuild aging roads and bridges",                  %w[jobs economy]],
  ["Strengthen veterans' mental health services",      %w[veterans healthcare]],
  ["Make Election Day a national holiday",             %w[democracy]],
  ["Build more affordable housing near transit",       %w[housing economy]],
  ["Expand rural broadband access",                    %w[technology jobs]],
  ["Create a national service program for young people", %w[education jobs]]
]

points_for = [
  "It would create hundreds of thousands of good-paying jobs.",
  "Other countries that did this saw measurable improvements within a decade.",
  "The long-term savings far outweigh the upfront cost.",
  "It addresses a problem that affects families in every part of the country.",
  "Independent studies show broad public support for this."
]
points_against = [
  "The cost would add significantly to the deficit.",
  "Implementation would be difficult without state cooperation.",
  "It could have unintended consequences for small businesses.",
  "There are more urgent priorities that should come first."
]

if Priority.count < priority_seeds.size
  priority_seeds.each do |name, tags|
    author = everyone.sample
    next if Priority.exists?(name: name)
    p = Priority.new(name: name, user: author, status: "published")
    p.save!
    p.update!(cached_issue_list: tags.join(","))
    tags.each do |tname|
      tag = Tag.find_by(slug: tname)
      p.taggings.create!(tag: tag) if tag
    end

    # Endorsements: most up, some down
    voters = everyone.shuffle.first(rand(4..everyone.size))
    voters.each do |u|
      if rand < 0.78
        p.endorse(u)
      else
        p.oppose(u)
      end
    end

    # Points for/against
    rand(1..3).times do
      author2 = everyone.sample
      p.points.create!(user: author2, value: 1, name: points_for.sample.truncate(70),
                       content: points_for.sample, status: "published")
    end
    rand(0..2).times do
      author2 = everyone.sample
      p.points.create!(user: author2, value: -1, name: points_against.sample.truncate(70),
                       content: points_against.sample, status: "published")
    end

    # A document
    if rand < 0.4
      p.documents.create!(user: everyone.sample, value: 1,
                          name: "The case for: #{name}",
                          content: "#{points_for.sample} #{points_for.sample}\n\n#{points_for.sample}",
                          status: "published")
    end
  end
end

# Rate some points helpful
Point.all.each do |pt|
  everyone.sample(rand(0..5)).each do |u|
    PointQuality.find_or_create_by!(user: u, point: pt) { |q| q.value = (rand < 0.8) }
  end
end

# Comments on a few activities
sample_comments = [
  "Strongly agree with this.",
  "I'm not so sure — how would we pay for it?",
  "This is my number one issue.",
  "Great point, hadn't considered that angle.",
  "We tried something similar locally and it worked."
]
Activity.where(type: %w[ActivityPriorityNew ActivityPointNew]).order(Arel.sql("RANDOM()")).limit(20).each do |a|
  rand(0..3).times do
    a.comments.create!(user: everyone.sample, content: sample_comments.sample, status: "published")
  end
end

# Follows
members.each do |u|
  others = (everyone - [u]).sample(rand(0..3))
  others.each { |o| Following.find_or_create_by!(user: u, other_user: o) { |f| f.value = 1 } }
end

# Static pages
{
  "about" => ["About", "This is a modern rebuild of White House 2, an open-source platform where thousands of people set priorities together and debate what the government should do.\n\nEndorse the ideas you support, oppose the ones you don't, rank them, and add points to make your case."],
  "how-it-works" => ["How it works", "1. Add a priority — something you think the government should do.\n2. Endorse or oppose priorities, and rank your own list.\n3. Make points for and against.\n4. The community's combined rankings produce the leaderboard."],
  "privacy" => ["Privacy", "This is a demo application. Don't enter real personal information."]
}.each do |slug, (name, content)|
  Page.find_or_create_by!(short_name: slug) { |pg| pg.name = name; pg.content = content; pg.link_name = name }
end

# Recompute counters and leaderboard
User.find_each do |u|
  active = u.endorsements.where(status: "active")
  u.update_columns(
    endorsements_count: active.count,
    up_endorsements_count: active.where("value > 0").count,
    down_endorsements_count: active.where("value < 0").count,
    points_count: u.points.count
  )
end
gov.update_columns(
  priorities_count: Priority.published.count,
  users_count: User.count,
  points_count: Point.count,
  documents_count: Document.count,
  endorsements_count: Endorsement.count
)
Priority.recalculate_positions!

puts "Done. #{User.count} users, #{Priority.count} priorities, #{Point.count} points, #{Endorsement.count} endorsements."
puts "Log in with any of these (password: #{PASSWORD}):"
puts "  president@example.gov  (official + admin)"
puts "  admin@example.com      (admin)"
puts "  jordan@example.com     (member)"
