require 'test_helper'

class SignupsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_show_signup
    get :show, params: { :id => signups(:one).id }
    assert_response :success
  end

  def test_should_create_signup
    assert_difference('Signup.count') do
      post :create, params: { :signup => { :user_id => LegacyTestData.fixture('users', :quentin).id } }
    end
    assert_response :redirect
  end

  def test_should_get_edit
    get :edit, params: { :id => signups(:one).id }
    assert_response :success
  end

  def test_should_update_signup
    put :update, params: { :id => signups(:one).id, :signup => { :is_optin => true } }
    assert_response :redirect
  end

  def test_should_destroy_signup
    target = signups(:one)
    assert_difference('Signup.count', -1) do
      delete :destroy, params: { :id => target.id }
    end
    assert_response :redirect
  end
end
