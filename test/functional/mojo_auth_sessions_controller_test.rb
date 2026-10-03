require File.dirname(__FILE__) + '/../test_helper'

class MojoAuthSessionsControllerTest < ActionController::TestCase
  fixtures :users

  # Lightweight seam: replace the service's verify method for the block, then
  # restore it. (minitest/mock is not shipped in this legacy gem set.)
  def with_verified_identifier(identifier)
    original = MojoAuthService.method(:verify_access_token)
    MojoAuthService.define_singleton_method(:verify_access_token) { |_token| identifier }
    yield
  ensure
    MojoAuthService.define_singleton_method(:verify_access_token, original)
  end

  def test_logs_in_existing_user_by_email
    quentin = users(:quentin)

    with_verified_identifier(quentin.email) do
      assert_no_difference 'User.count' do
        post :create, params: { :access_token => 'good-token' }
      end
    end

    assert_response :success
    assert_equal quentin.id, session[:user_id]
    body = JSON.parse(@response.body)
    assert body['ok']
  end

  def test_provisions_and_activates_user_on_first_login
    with_verified_identifier('newcomer@example.com') do
      assert_difference 'User.count', 1 do
        post :create, params: { :access_token => 'good-token' }
      end
    end

    assert_response :success
    user = User.find_by(email: 'newcomer@example.com')
    assert_not_nil user
    assert user.active?
    assert_not_nil user.activated_at
    assert_nil user.activation_code
    assert_equal user.id, session[:user_id]
    assert_not_nil @response.cookies['auth_token']
  end

  def test_rejects_invalid_token
    with_verified_identifier(nil) do
      assert_no_difference 'User.count' do
        post :create, params: { :access_token => 'bad-token' }
      end
    end

    assert_response :unauthorized
    assert_nil session[:user_id]
    body = JSON.parse(@response.body)
    assert !body['ok']
  end

  def test_refuses_suspended_user
    quentin = users(:quentin)
    quentin.suspend!

    with_verified_identifier(quentin.email) do
      post :create, params: { :access_token => 'good-token' }
    end

    assert_response :forbidden
    assert_nil session[:user_id]
  end
end
