require "test_helper"

class EndorsementTest < ActiveSupport::TestCase
  setup do
    @user = create_user("ranker", score: 1.0)
    @priority = Priority.create!(name: "Fund public libraries", user: @user, status: "published")
  end

  test "score is weighted by position and user score" do
    e = @priority.endorse(@user)
    # position 1, value 1, score 1.0 => (100 - 1) * 1 * 1.0 = 99
    assert_equal 99, e.reload.score
  end

  test "second endorsement goes to the bottom of the user's list" do
    e1 = @priority.endorse(@user)
    other = Priority.create!(name: "Repair sidewalks", user: @user, status: "published")
    e2 = other.endorse(@user)
    assert_equal 1, e1.reload.position
    assert_equal 2, e2.reload.position
  end

  test "a user can only endorse a priority once" do
    @priority.endorse(@user)
    dup = Endorsement.new(user: @user, priority: @priority, value: 1)
    assert_not dup.valid?
  end
end
