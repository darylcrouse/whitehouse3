require 'test_helper'

# This app only exposes edit/update (/governments/:id) plus the XML apis.
class GovernmentsControllerTest < ActionController::TestCase
  def test_should_get_edit
    login_as_user
    get :edit, params: { :id => Government.first.id }
    assert_response :success
  end

  def test_should_update_government
    login_as_user
    put :update, params: { :id => Government.first.id, :government => { :name => Government.first.name } }
    assert_response :redirect
  end
end
