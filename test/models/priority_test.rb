require "test_helper"

class PriorityTest < ActiveSupport::TestCase
  setup do
    @author = create_user("author")
    @priority = Priority.create!(name: "Build more bike lanes", user: @author, status: "published")
  end

  test "is created with a published_at and a debut activity" do
    assert @priority.published_at.present?
    assert ActivityPriorityNew.exists?(priority_id: @priority.id)
  end

  test "endorse creates an up endorsement and bumps counts" do
    user = create_user("voter")
    @priority.endorse(user)
    @priority.reload
    assert_equal 1, @priority.up_endorsements_count
    assert_equal 1, @priority.endorsements_count
    assert user.endorsed?(@priority)
  end

  test "oppose then endorse flips the endorsement without duplicating" do
    user = create_user("flipper")
    @priority.oppose(user)
    @priority.endorse(user)
    @priority.reload
    assert_equal 1, @priority.endorsements.count
    assert_equal 1, @priority.up_endorsements_count
    assert_equal 0, @priority.down_endorsements_count
    assert user.endorsed?(@priority)
  end

  test "unendorse removes the endorsement and decrements counts" do
    user = create_user("remover")
    @priority.endorse(user)
    @priority.unendorse(user)
    @priority.reload
    assert_equal 0, @priority.endorsements_count
    assert_not user.endorsed?(@priority)
  end

  test "recalculate_positions ranks higher-scored priorities first" do
    other = Priority.create!(name: "Plant street trees", user: @author, status: "published")
    3.times { |i| @priority.endorse(create_user("voter#{i}")) }
    other.endorse(create_user("solo"))
    Priority.recalculate_positions!
    assert @priority.reload.position < other.reload.position
  end

  test "name must be unique and present" do
    dup = Priority.new(name: "Build more bike lanes")
    assert_not dup.valid?
    assert dup.errors[:name].present?
  end

  test "issue_list assigns tags and caches the list" do
    @priority.issue_list = "transit, environment"
    @priority.save!
    assert_equal %w[transit environment], @priority.issue_list
    assert_equal 2, @priority.tags.count
  end
end
