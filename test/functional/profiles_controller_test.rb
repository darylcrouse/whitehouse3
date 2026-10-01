require 'test_helper'

# Singleton resource: /users/:user_id/profile (no index).
class ProfilesControllerTest < ActionController::TestCase
  def user_params(extra = {})
    { :user_id => LegacyTestData.admin.id }.merge(extra)
  end

  def ensure_profile
    Profile.find_by_user_id(LegacyTestData.admin.id) || Profile.create!(:user_id => LegacyTestData.admin.id)
  end

  def test_should_get_new
    login_as_user
    get :new, params: user_params
    assert_response :success
  end

  def test_should_create_profile
    login_as_user
    assert_difference('Profile.count') do
      post :create, params: user_params(:profile => { :bio => 'Fixture bio.' })
    end
    assert_response :redirect
  end

  def test_should_show_profile
    login_as_user
    ensure_profile
    get :show, params: user_params
    assert_redirected_to user_path(LegacyTestData.admin)
  end

  def test_should_get_edit
    login_as_user
    ensure_profile
    get :edit, params: user_params
    assert_response :success
  end

  def test_should_update_profile
    login_as_user
    ensure_profile
    put :update, params: user_params(:profile => { :bio => 'Updated fixture bio.' })
    assert_response :redirect
  end

  def test_should_destroy_profile
    login_as_user
    ensure_profile
    assert_difference('Profile.count', -1) do
      delete :destroy, params: user_params
    end
    assert_response :redirect
  end
end
