# Bootstraps the singleton data every legacy page assumes (Government +
# ColorScheme + admin user + one tagged issue with priorities) and backs the
# Rails-2 fixture accessors (`priorities(:one)`, `users(:quentin)` …) that the
# 2009-era tests use — this repo has no fixture YAMLs, so rows are built on
# demand inside each test's transaction.
module LegacyTestData
  module_function

  # ---- world bootstrap -----------------------------------------------------

  def ensure!
    return Government.first if Government.first && User.exists? && Priority.exists?

    scheme = ColorScheme.create!(name: 'Default')
    gov = Government.new(
      status: 'active',
      name: 'The White House 2',
      short_name: 'wh2',
      domain_name: 'localhost',
      layout: 'wh2',
      tagline: 'Together we decide what the government should do.',
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
    Government.current = gov
    Thread.current[:government] = gov

    admin = user!(login: 'admin', email: 'admin@example.gov', is_admin: true)
    gov.update_columns(official_user_id: admin.id, official_user_short_name: admin.login)

    %w[Economy Health\ Care Energy].each do |tag_name|
      names = Array.new(5) { |i| "#{tag_name} fixture priority #{i + 1}" }
      names.each do |name|
        p = Priority.new(name: name, user_id: admin.id, status: 'published',
                         published_at: Time.now.utc, ip_address: '127.0.0.1')
        p.save(validate: false)
        p.issue_list.add(tag_name)
        p.save(validate: false)
      end
      tag = Tag.find_by_name(tag_name)
      tag.update_counts if tag
    end

    # A point + a change + an activity, so the nested resources
    # (points/revisions, priorities/changes/votes, activities/comments) exist.
    point = Point.new(name: 'Fixture point', content: 'Fixture point content.',
                      priority_id: Priority.first.id, user_id: admin.id, value: 1,
                      status: 'published', published_at: Time.now.utc)
    point.save(validate: false)

    revision = Revision.new(point_id: point.id, user_id: admin.id,
                            name: point.name, content: point.content, value: 1,
                            status: 'published', published_at: Time.now.utc)
    revision.save(validate: false)
    point.update_columns(revision_id: revision.id)

    change = Change.new(priority_id: Priority.first.id, status: 'suggested',
                        new_priority_id: Priority.last.id, user_id: admin.id)
    change.save(validate: false)

    activity = Activity.new(user_id: admin.id, priority_id: Priority.first.id,
                            status: 'active')
    activity.save(validate: false)

    gov
  end

  def admin
    ensure! && User.find_by_login('admin')
  end

  def user!(login:, email: nil, password: 'password123', **extra)
    # Fixtures are per-test singletons: repeated access returns the same row.
    existing = User.find_by_login(login)
    return existing if existing

    u = User.new({
      login: login,
      email: email || "#{login}@example.com",
      first_name: login.to_s.titleize,
      last_name: 'Test',
      status: 'active',
      activated_at: Time.now.utc,
      is_branch_chosen: true
    }.merge(extra))
    u.password = password
    u.save(validate: false)
    u
  end

  # ---- Rails-2 fixture accessor support ------------------------------------

  # Models the 2009 tests ask for by fixture accessor.
  FIXTURE_MODELS = %w[
    activities ads blurbs branches changes color_schemes comments email_templates
    endorsements followings governments notifications pages partners
    points priorities profiles revisions signups tags unsubscribes users
    votes
  ].freeze

  def fixture_model?(name)
    FIXTURE_MODELS.include?(name.to_s)
  end

  # Fixture rows live inside each test's transaction; the memo must not leak
  # stale instances (rolled-back rows) across tests.
  def reset!
    @fixtures = {}
  end

  def fixture(model, name)
    @fixtures ||= {}
    @fixtures[[model.to_s, name]] ||= build_fixture(model.to_s, name.to_s)
  end

  def build_fixture(model, name)
    case model
    when 'users'
      # The 2009 tests log in as `quentin`/`aaron`; aaron must stay
      # unauthenticatable until his activation code is used.
      u = user!(login: name, email: "#{name}@example.com", password: 'test')
      if name.to_s == 'aaron' && u.status != 'passive'
        u.update_columns(status: 'passive', activation_code: 'aaron-activation-code')
        u = User.find(u.id)
      end
      u
    when 'governments'
      ensure!
    when 'activities'
      a = Activity.new(user_id: admin.id, priority_id: Priority.first&.id,
                       status: 'active')
      a.save(validate: false)
      a
    when 'priorities'
      p = Priority.new(name: "Fixture priority #{name}", user_id: admin.id,
                       status: 'published', published_at: Time.now.utc,
                       ip_address: '127.0.0.1')
      p.save(validate: false)
      p
    when 'tags'
      tag = Tag.find_by_name("Fixture tag #{name}")
      unless tag
        p = Priority.new(name: "Tagged priority #{name}", user_id: admin.id,
                         status: 'published', published_at: Time.now.utc,
                         ip_address: '127.0.0.1')
        p.save(validate: false)
        p.issue_list.add("Fixture tag #{name}")
        p.save(validate: false)
        tag = Tag.find_by_name("Fixture tag #{name}")
        tag.update_counts if tag
      end
      tag
    when 'points'
      pt = Point.new(name: "Fixture point #{name}", content: 'Fixture point body.',
                     priority_id: Priority.first&.id, user_id: admin.id, value: 1,
                     status: 'published', published_at: Time.now.utc)
      pt.save(validate: false)
      rev = Revision.new(point_id: pt.id, user_id: admin.id, name: pt.name,
                         content: pt.content, value: 1, status: 'published',
                         published_at: Time.now.utc)
      rev.save(validate: false)
      pt.update_columns(revision_id: rev.id)
      pt
    when 'changes'
      Change.new(id: nil, priority_id: Priority.first&.id, user_id: admin.id,
                 status: 'suggested',
                 new_priority_id: Priority.last&.id) { |c| c.save(validate: false) }
    when 'endorsements'
      e = Endorsement.new(user_id: admin.id, priority_id: Priority.first&.id,
                          position: 1, value: 1)
      e.save(validate: false)
      e
    when 'followings'
      f = Following.new(user_id: admin.id, other_user_id: user!(login: "fixture_followee_#{name}").id, value: 1)
      f.save(validate: false)
      f
    when 'comments'
      c = Comment.new(content: "Fixture comment #{name}", user_id: admin.id,
                      activity_id: Activity.first&.id)
      c.save(validate: false)
      c
    when 'notifications'
      c = Comment.first
      unless c
        c = Comment.new(content: 'Fixture notification comment.', user_id: admin.id,
                        activity_id: Activity.first&.id)
        c.save(validate: false)
      end
      n = Notification.new(recipient_id: admin.id, sender_id: admin.id,
                           type: 'NotificationComment', status: 'sent',
                           notifiable_id: c.id, notifiable_type: 'Comment')
      n.save(validate: false)
      n
    when 'votes'
      v = Vote.new(change_id: Change.first&.id, user_id: admin.id, value: 1)
      v.save(validate: false)
      v
    when 'ads'
      a = Ad.new(priority_id: Priority.first&.id, user_id: admin.id,
                 content: "Fixture ad #{name}", cost: 5, show_ads_count: 100)
      a.save(validate: false)
      a
    when 'partners'
      pt = Partner.new(name: "Fixture partner #{name}", short_name: "fixture-partner-#{name}")
      pt.save(validate: false)
      pt
    when 'profiles'
      pr = Profile.new(user_id: admin.id)
      pr.save(validate: false)
      pr
    when 'signups'
      s = Signup.new(user_id: admin.id)
      s.save(validate: false)
      s
    when 'email_templates'
      EmailTemplate.create!(name: "fixture_#{name}")
    when 'color_schemes'
      cs = ColorScheme.new(name: "Fixture scheme #{name}")
      cs.save(validate: false)
      cs
    when 'branches'
      b = Branch.new(name: "Fixture branch #{name}")
      b.save(validate: false)
      b
    when 'blurbs'
      b = Blurb.new(name: "Fixture blurb #{name}")
      b.save(validate: false)
      b
    when 'pages'
      pg = Page.new(name: "Fixture page #{name}", short_name: "fixture-page-#{name}")
      pg.save(validate: false)
      pg
    when 'revisions'
      r = Revision.new(point_id: Point.first&.id, user_id: admin.id,
                       name: 'Fixture revision', content: 'Fixture revision content.',
                       value: 1, status: 'published', published_at: Time.now.utc)
      r.save(validate: false)
      r
    when 'unsubscribes'
      u = Unsubscribe.new(email: admin.email, user_id: admin.id)
      u.save(validate: false)
      u
    else
      raise NoMethodError, "no fixture builder for #{model}"
    end
  end
end
