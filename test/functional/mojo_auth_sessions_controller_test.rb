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

  # --- our own OTP form: start -> verify ----------------------------------

  def with_stub(method_name, result)
    original = MojoAuthService.method(method_name)
    MojoAuthService.define_singleton_method(method_name) { |*_args| result }
    yield
  ensure
    MojoAuthService.define_singleton_method(method_name, original)
  end

  def test_start_rejects_malformed_email
    assert_no_difference 'User.count' do
      post :start, params: { :email => 'not-an-email' }
    end
    assert_response :unprocessable_entity
    assert_not JSON.parse(@response.body)['ok']
  end

  def test_start_stores_challenge_and_returns_email
    with_stub(:request_email_otp, [200, { 'state_id' => 'abc123' }]) do
      post :start, params: { :email => 'Someone@Example.COM' }
    end

    assert_response :success
    body = JSON.parse(@response.body)
    assert body['ok']
    assert_equal 'someone@example.com', body['email']
    assert_equal 'abc123', session[:mojo_state_id]
    assert_equal 'someone@example.com', session[:mojo_email]
  end

  def test_start_surfaces_api_failure
    with_stub(:request_email_otp, [500, { 'message' => 'boom' }]) do
      post :start, params: { :email => 'someone@example.com' }
    end

    assert_response :bad_gateway
    assert_not JSON.parse(@response.body)['ok']
    assert_nil session[:mojo_state_id]
  end

  def test_verify_without_challenge_asks_to_restart
    post :verify, params: { :code => '123456' }
    assert_response :unauthorized
    body = JSON.parse(@response.body)
    assert_not body['ok']
    assert body['restart']
  end

  def test_verify_rejects_bad_code
    @request.session[:mojo_state_id] = 'abc123'
    @request.session[:mojo_state_at] = Time.now.to_i
    @request.session[:mojo_email] = 'someone@example.com'

    with_stub(:verify_email_otp, [400, { 'message' => 'Invalid OTP' }]) do
      post :verify, params: { :code => '000000' }
    end

    assert_response :unauthorized
    assert_nil session[:user_id]
    assert_equal 'abc123', session[:mojo_state_id], 'a wrong code must not burn the challenge'
  end

  def test_verify_expires_stale_challenge
    @request.session[:mojo_state_id] = 'abc123'
    @request.session[:mojo_state_at] = (Time.now - 20 * 60).to_i
    @request.session[:mojo_email] = 'someone@example.com'

    post :verify, params: { :code => '123456' }

    assert_response :unauthorized
    assert JSON.parse(@response.body)['restart']
    assert_nil session[:mojo_state_id]
  end

  def test_start_is_paced_between_requests
    with_stub(:request_email_otp, [200, { 'state_id' => 'abc123' }]) do
      post :start, params: { :email => 'someone@example.com' }
      assert_response :success
      post :start, params: { :email => 'someone@example.com' }
    end
    assert_response :too_many_requests
    assert_not JSON.parse(@response.body)['ok']
  end

  def test_start_allows_retry_after_cooldown
    with_stub(:request_email_otp, [200, { 'state_id' => 'abc123' }]) do
      post :start, params: { :email => 'someone@example.com' }
      assert_response :success
      @request.session[:mojo_start_at] = Time.now.to_i - 60
      post :start, params: { :email => 'someone@example.com' }
    end
    assert_response :success
  end

  def test_provisioning_picks_a_free_login_handle
    User.create!(email: 'johndoe@example.com', login: 'johndoe',
                 first_name: 'John', last_name: 'Doe',
                 password: 'secret123', password_confirmation: 'secret123')

    # Different address, same sanitized handle -> must not fail on uniqueness.
    with_stub(:verify_email_otp, [200, { 'oauth' => { 'access_token' => 'tok' },
                                         'user' => { 'identifier' => 'johndoe@example.org' } }]) do
      @request.session[:mojo_state_id] = 'abc123'
      @request.session[:mojo_state_at] = Time.now.to_i
      @request.session[:mojo_email] = 'johndoe@example.org'
      post :verify, params: { :code => '123456' }
    end

    assert_response :success
    created = User.where(email: 'johndoe@example.org').first
    assert created, 'account should be provisioned'
    assert_equal 'johndoe2', created.login
  end

  def test_verify_signs_in_and_provisions_on_first_login
    quentin = users(:quentin)
    @request.session[:mojo_state_id] = 'abc123'
    @request.session[:mojo_state_at] = Time.now.to_i
    @request.session[:mojo_email] = quentin.email

    with_stub(:verify_email_otp, [200, { 'oauth' => { 'access_token' => 'tok' },
                                         'user' => { 'identifier' => quentin.email } }]) do
      assert_no_difference 'User.count' do
        post :verify, params: { :code => '123456' }
      end
    end

    assert_response :success
    assert_equal quentin.id, session[:user_id]
    assert_nil session[:mojo_state_id], 'challenge should be consumed'
    assert JSON.parse(@response.body)['ok']
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

  def test_honors_internal_return_to
    @request.session[:return_to] = "/priorities/2"

    with_verified_identifier(users(:quentin).email) do
      post :create, params: { :access_token => 'good-token' }
    end

    body = JSON.parse(@response.body)
    assert body['ok']
    assert_equal "/priorities/2", body['redirect']
  end

  def test_ignores_external_return_to
    @request.session[:return_to] = "https://evil.example.com/phish"

    with_verified_identifier(users(:quentin).email) do
      post :create, params: { :access_token => 'good-token' }
    end

    body = JSON.parse(@response.body)
    assert body['ok']
    assert_equal "/", body['redirect']
  end
end
