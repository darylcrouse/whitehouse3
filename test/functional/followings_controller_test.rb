require 'test_helper'

# Nested under users/:user_id (get_user); login required.
class FollowingsControllerTest < ActionController::TestCase
  def user_params(extra = {})
    { :user_id => LegacyTestData.admin.id }.merge(extra)
  end

  def test_should_get_index
    login_as_user
    get :index, params: user_params
    assert_response :success
  end

  def test_should_get_new
    login_as_user
    get :new, params: user_params
    assert_response :success
  end

  def test_should_create_following
    login_as_user
    assert_difference('Following.count') do
      post :create, params: user_params(:following => { :other_user_id => LegacyTestData.fixture('users', :quentin).id })
    end
    assert_response :redirect
  end

  def test_should_show_following
    login_as_user
    get :show, params: user_params(:id => followings(:one).id)
    assert_response :success
  end

  def test_should_get_edit
    login_as_user
    get :edit, params: user_params(:id => followings(:one).id)
    assert_response :success
  end

  def test_should_update_following
    login_as_user
    put :update, params: user_params(:id => followings(:one).id, :following => { :value => 2 })
    assert_response :redirect
  end

  def test_should_destroy_following
    login_as_user
    target = followings(:one)
    assert_difference('Following.count', -1) do
      delete :destroy, params: user_params(:id => target.id)
    end
    assert_response :redirect
  end
end
