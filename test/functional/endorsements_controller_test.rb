require 'test_helper'

# Endorsements have no create/show/new; index redirects to your priorities;
# edit/update/destroy are JS (rjs) endpoints.
class EndorsementsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_redirected_to yours_priorities_url
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => endorsements(:one).id, :region => 'yours', :format => :js }, xhr: true
    assert_response :success
  end

  def test_should_update_endorsement
    login_as_user
    put :update, params: { :id => endorsements(:one).id, :region => 'yours', :endorsement => { :position => 1 }, :format => :js }
    assert_response :success
  end

  def test_should_destroy_endorsement
    login_as_user
    target = endorsements(:one)
    assert_difference('Endorsement.count', -1) do
      delete :destroy, params: { :id => target.id, :format => :js }
    end
    assert_response :success
  end
end
