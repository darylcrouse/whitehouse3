require File.dirname(__FILE__) + '/../test_helper'

class SessionsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  fixtures :users

  def test_should_login_and_redirect
    post :create, params: { :email => 'quentin@example.com', :password => 'test' }
    assert session[:user_id]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :create, params: { :email => 'quentin@example.com', :password => 'bad password' }
    assert_nil session[:user_id]
    assert_response :success
  end

  def test_should_logout
    login_as :quentin
    get :destroy
    assert_nil session[:user_id]
    assert_response :redirect
  end

  def test_should_remember_me
    post :create, params: { :email => 'quentin@example.com', :password => 'test', :remember_me => "1" }
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    post :create, params: { :email => 'quentin@example.com', :password => 'test', :remember_me => "0" }
    assert_nil @response.cookies["auth_token"]
  end

  def test_should_delete_token_on_logout
    login_as :quentin
    get :destroy
    assert_nil @response.cookies["auth_token"]
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :new
    assert !@controller.send(:logged_in?)
  end

  protected

  # The 2009 helper built CGI::Cookie objects; Rack's request cookie jar
  # stores plain strings, which is also what the app reads (cookies[:auth_token]).
  def auth_token(token)
    token
  end

  # Regression guard: the MojoAuth SDK owns the id "mojoauth-login" internally
  # and does document.getElementById('mojoauth-login') when it swaps the email
  # form for the OTP screen. A wrapper div with that same id made its cleanup
  # removeChild the wrong node, so every sign-in click died silently before any
  # OTP request was sent. Our markup must never claim that id.
  def test_login_page_does_not_collide_with_mojoauth_sdk_ids
    get :new
    assert_response :success
    assert_match(/id="mojoauth-passwordless-form"/, @response.body)
    assert_no_match(/id="mojoauth-login"/, @response.body)
  end

  def cookie_for(user)
    auth_token users(user).remember_token
  end
end
