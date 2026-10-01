require 'test_helper'

# Only show/destroy exist; both need a logged-in admin in this app.
class NotificationsControllerTest < ActionController::TestCase
  def test_should_show_notification
    login_as_user
    get :show, params: { :id => notifications(:one).id }
    assert_response :success
  end

  def test_should_destroy_notification
    login_as_user
    delete :destroy, params: { :id => notifications(:one).id }
    assert_response :redirect
  end
end
