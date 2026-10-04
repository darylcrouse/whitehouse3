require 'test_helper'

# WH3 common-ground score: "support in the group that likes it least".
class CommonGroundTest < ActiveSupport::TestCase
  def setup
    super
    # Four voters in two blocs, split by voting pattern (never by party):
    #   bloc a: u1 + u2 vote together everywhere
    #   bloc b: u3 votes opposite; u4 agrees with u3 on the first two only
    @u1 = make_user('cg_u1')
    @u2 = make_user('cg_u2')
    @u3 = make_user('cg_u3')
    @u4 = make_user('cg_u4')

    # Pattern priorities carry the bloc signal:
    #   u1/u2: +++++    u3: -----    u4: +----  (u4 mostly agrees with u3)
    pattern = []
    5.times { |n| pattern << make_priority("CG pattern #{n}") }
    pattern.each_with_index do |p, n|
      vote(@u1, p, 1); vote(@u2, p, 1)
      vote(@u3, p, -1)
      vote(@u4, p, n.zero? ? 1 : -1)
    end

    @p_all = make_priority('CG all agree')
    @p_split = make_priority('CG split')
    @p_mixed = make_priority('CG mixed support')
    @p_one_group = make_priority('CG one group only')

    # Both blocs endorse -> weakest group 100%
    [@u1, @u2, @u3, @u4].each { |u| vote(u, @p_all, 1) }

    # Bloc a endorses, bloc b opposes -> weakest group 0%
    vote(@u1, @p_split, 1); vote(@u2, @p_split, 1)
    vote(@u3, @p_split, -1); vote(@u4, @p_split, -1)

    # Bloc a 100%, bloc b 50% (u3 opposes, u4 endorses) -> weakest 50%
    vote(@u1, @p_mixed, 1); vote(@u2, @p_mixed, 1)
    vote(@u3, @p_mixed, -1); vote(@u4, @p_mixed, 1)

    # Only bloc a votes -> one group alone cannot produce a score
    vote(@u1, @p_one_group, 1); vote(@u2, @p_one_group, 1)
  end

  def test_opinion_groups_split_by_voting_pattern
    groups = CommonGround.opinion_groups
    assert_equal 2, groups.size
    a, b = groups['a'], groups['b']
    assert_equal [@u1.id, @u2.id].sort, a.sort
    assert_equal [@u3.id, @u4.id].sort, b.sort
  end

  def test_scores_are_support_in_the_weakest_group
    CommonGround.recompute!
    assert_equal 100, @p_all.reload.common_ground_score
    assert_equal 0,   @p_split.reload.common_ground_score
    assert_equal 50,  @p_mixed.reload.common_ground_score
  end

  def test_one_group_alone_cannot_produce_a_score
    CommonGround.recompute!
    assert_equal 0, @p_one_group.reload.common_ground_score
  end

  def test_common_ground_scope_ranks_scored_priorities
    CommonGround.recompute!
    ids = Priority.published.common_ground.pluck(:id)
    assert_includes ids, @p_all.id
    assert_includes ids, @p_mixed.id
    assert_not_includes ids, @p_split.id
    assert_not_includes ids, @p_one_group.id
    assert_operator ids.index(@p_all.id), :<, ids.index(@p_mixed.id)
  end

  private

  def make_user(login)
    u = User.new(login: login, email: "#{login}@example.com",
                 first_name: login.titleize, last_name: 'Test',
                 status: 'active', activated_at: Time.now.utc, is_branch_chosen: true)
    u.password = 'password123'
    u.save(validate: false)
    u
  end

  def make_priority(name)
    p = Priority.new(name: name, user_id: LegacyTestData.admin.id, status: 'published',
                     published_at: Time.now.utc, ip_address: '127.0.0.1')
    p.save(validate: false)
    p
  end

  def vote(user, priority, value)
    e = Endorsement.new(user_id: user.id, priority_id: priority.id,
                        position: 1, value: value, status: 'active')
    e.save(validate: false)
    e
  end
end
