require 'test_helper'

# The app nests votes under priorities/:priority_id/changes/:change_id and
# gates every action on login (edit/update/destroy admin-only):
# see VotesController before_actions.
class VotesControllerTest < ActionController::TestCase
  def change_params(extra = {})
    { :priority_id => Priority.first.id, :change_id => Change.first.id }.merge(extra)
  end

  def test_should_create_vote
    login_as_user
    assert_difference('Vote.count') do
      post :create, params: change_params(:vote => { :value => 1, :user_id => LegacyTestData.admin.id })
    end
    assert_redirected_to priority_change_vote_path(Priority.first, Change.first, assigns(:vote))
  end

  def test_should_update_vote
    login_as_user
    target = votes(:one)
    put :update, params: change_params(:id => target.id, :vote => { :value => 1 })
    assert_redirected_to priority_change_vote_path(Priority.first, Change.first, assigns(:vote))
  end

  def test_should_destroy_vote
    login_as_user
    target = votes(:one)
    assert_difference('Vote.count', -1) do
      delete :destroy, params: change_params(:id => target.id)
    end
    assert_response :redirect
  end
end
