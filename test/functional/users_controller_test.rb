require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users

  def test_should_allow_signup
    assert_difference 'User.count' do
      create_user
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'User.count' do
      create_user(:login => nil)
      assert assigns(:user).errors[:login].any?
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'User.count' do
      create_user(:password => nil)
      assert assigns(:user).errors[:password].any?
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'User.count' do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors[:password_confirmation].any?
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'User.count' do
      create_user(:email => nil)
      assert assigns(:user).errors[:email].any?
      assert_response :success
    end
  end
  

  
  def test_should_sign_up_user_with_activation_code
    create_user
    user = assigns(:user)
    # Signups start passive; the welcome flow mints an activation code once the
    # account is pending (User#new_user_signedup -> resend_activation).
    user.update_columns(status: 'pending')
    user.resend_activation
    assert_not_nil user.reload.activation_code
  end

  def test_should_activate_user
    assert_nil User.authenticate('aaron', 'test')
    get :activate, params: { :activation_code => users(:aaron).activation_code }
    assert_redirected_to '/'
    assert_not_nil flash[:notice]
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
  end
  
  def test_should_not_activate_user_without_key
    get :activate
    assert_response :redirect
    assert_nil session[:user_id]
  rescue ActionController::RoutingError
    # in the event your routes deny this, we'll just bow out gracefully.
  end

  def test_should_not_activate_user_with_blank_key
    get :activate, params: { :activation_code => '' }
    assert_response :redirect
    assert_nil session[:user_id]
  rescue ActionController::RoutingError
    # well played, sir
  end

  protected
    def create_user(options = {})
      post :create, params: { :user => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire', :password_confirmation => 'quire' }.merge(options) }
    end
end
