require 'test_helper'

# Only new/create exist in this app.
class UnsubscribesControllerTest < ActionController::TestCase
  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_unsubscribe
    assert_difference('Unsubscribe.count') do
      post :create, params: { :unsubscribe => { :email => LegacyTestData.admin.email } }
    end
    assert_response :redirect
  end
end
