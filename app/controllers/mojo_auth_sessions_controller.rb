# Passwordless login for the MojoAuth email-OTP flow.
#
# We drive the OTP flow ourselves (start -> verify) instead of embedding the
# hosted widget. The widget inserts a WebAuthn/passkey enrolment step after
# the code whenever the project has webauthn enabled, and that step cannot
# work on an insecure origin (plain http on a LAN address): its "Continue"
# button silently does nothing. Calling the REST API from the server also
# keeps the API key out of the browser.
#
# start:  POST email        -> MojoAuth /users/emailotp; state_id lives in the
#                              session, MojoAuth emails the code.
# verify: POST code         -> MojoAuth /users/emailotp/verify, then map the
#                              address to a legacy User (provisioning on first
#                              login) and establish the app session.
# create: POST access_token -> legacy hand-off for clients that already hold a
#                              token; kept so existing integrations still work.
#
# CSRF: start/verify are called by our own page with the standard Rails token
# in an X-CSRF-Token header, so forgery protection stays ON. Only the legacy
# access-token hand-off below skips it, because its callers are server-side
# clients that hold a MojoAuth token and never load our form (the blast radius
# of a forged request there is login-CSRF into an account the attacker owns,
# and the request still needs a valid provider token).
class MojoAuthSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  OTP_STATE_TTL = 15 * 60   # seconds an emailed code stays usable
  START_COOLDOWN = 20       # seconds between "email me a code" requests
  START_MAX_PER_SESSION = 6

  # Step 1: email address -> OTP email.
  def start
    email = params[:email].to_s.strip.downcase

    unless email.match?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      return render json: { ok: false, error: t("sessions.new.passwordless.invalid_email") },
                    status: :unprocessable_entity
    end

    # Cheap throttle: this endpoint makes the provider send mail, so an
    # unlimited loop is an email-bomb and a bill.
    if (throttled = start_throttle)
      return render json: { ok: false, error: t("sessions.new.passwordless.too_many") },
                    status: :too_many_requests
    end

    status, data = MojoAuthService.request_email_otp(email)
    state_id = data["state_id"].to_s

    if status == 200 && state_id.present?
      reset_session_otp! # a new address invalidates any previous challenge
      session[:mojo_state_id] = state_id
      session[:mojo_state_at] = Time.now.to_i
      session[:mojo_email] = email
      render json: { ok: true, email: email }
    else
      Rails.logger.warn("[mojoauth] start failed for #{email}: HTTP #{status} #{data['message']}")
      render json: { ok: false, error: t("sessions.new.passwordless.send_failed") },
             status: :bad_gateway
    end
  end

  # Step 2: code -> session.
  def verify
    state_id = session[:mojo_state_id].to_s
    issued_at = session[:mojo_state_at].to_i
    email = session[:mojo_email].to_s

    if state_id.blank? || issued_at.zero? || (Time.now.to_i - issued_at) > OTP_STATE_TTL
      reset_session_otp!
      return render json: { ok: false, error: t("sessions.new.passwordless.expired"), restart: true },
                    status: :unauthorized
    end

    status, data = MojoAuthService.verify_email_otp(state_id, params[:code])

    unless status == 200 && data["oauth"].is_a?(Hash)
      Rails.logger.info("[mojoauth] verify rejected for #{email}: HTTP #{status} #{data['message']}")
      return render json: { ok: false, error: t("sessions.new.passwordless.bad_code") },
                    status: :unauthorized
    end

    # Prefer the identifier MojoAuth echoes back, falling back to the address
    # the code was sent to.
    identifier = data.dig("user", "identifier").presence || email
    reset_session_otp!

    user = find_or_provision_user(identifier.to_s.strip.downcase)
    return render_sign_in_failure(user) unless user
    return render_disabled(user) if sign_in_blocked?(user)

    sign_in_user(user)
    render json: { ok: true, redirect: safe_return_to }
  end

  # Legacy path: a client that already holds an access token posts it here.
  def create
    identifier = MojoAuthService.verify_access_token(params[:access_token].to_s)

    if identifier.blank?
      return render json: { ok: false, error: t("sessions.create.failed_passwordless") },
                    status: :unauthorized
    end

    user = find_or_provision_user(identifier.to_s.strip.downcase)
    return render_sign_in_failure(user) unless user
    return render_disabled(user) if sign_in_blocked?(user)

    sign_in_user(user)
    render json: { ok: true, redirect: safe_return_to }
  rescue StandardError => e
    Rails.logger.error("[mojoauth] login failed: #{e.class}: #{e.message}")
    render json: { ok: false, error: t("sessions.create.failed_passwordless") },
           status: :internal_server_error
  end

  private

  # Returns the User, or nil when provisioning failed.
  def find_or_provision_user(email)
    user = User.where("LOWER(email) = ?", email).first
    return user if user

    user = build_user_from_email(email)
    user.save ? user : nil
  end

  # Provisioning failed (invalid address or model validation).
  def render_sign_in_failure(_user = nil)
    render json: { ok: false, error: t("sessions.new.passwordless.provision_failed") },
           status: :unprocessable_entity
  end

  def sign_in_blocked?(user)
    user.deleted? || user.suspended?
  end

  def render_disabled(_user)
    render json: { ok: false, error: t("sessions.create.failed_account") },
           status: :forbidden
  end

  def sign_in_user(user)
    # MojoAuth has already proven ownership of this email address, so any
    # legacy activation state can be completed now.
    user.activate! if user.pending? || user.passive?
    user.update_attribute(:loggedin_at, Time.now) if user.respond_to?(:loggedin_at)

    self.current_user = user
    current_user.remember_me unless current_user.remember_token?
    cookies[:auth_token] = { value: current_user.remember_token,
                             expires: current_user.remember_token_expires_at }

    flash[:notice] = t("sessions.create.success", user_name: current_user.name)
  end

  def reset_session_otp!
    session.delete(:mojo_state_id)
    session.delete(:mojo_state_at)
    session.delete(:mojo_email)
  end

  # Per-session pacing for "email me a code". A fresh cookie jar resets this,
  # so it stops a stuck browser and casual loops, not a determined attacker;
  # real abuse control belongs in front of the app (proxy/WAF or provider
  # quota), and this app is not public yet.
  def start_throttle
    now = Time.now.to_i
    last = session[:mojo_start_at].to_i
    count = session[:mojo_start_count].to_i

    return :cooldown if last.positive? && (now - last) < START_COOLDOWN
    return :capped if count >= START_MAX_PER_SESSION

    session[:mojo_start_at] = now
    session[:mojo_start_count] = count + 1
    nil
  end

  # Where to send the browser after a successful sign-in. Honors the location
  # legacy store_location / store_previous_location saved (so deferred
  # endorsements and deep links survive the OTP round-trip), but only ever a
  # same-site path — never an external target.
  def safe_return_to
    location = session[:return_to]
    session[:return_to] = nil
    return "/" unless location.is_a?(String) && location.present?

    if location.start_with?("/")
      return "/" if location.start_with?("//")
      return location
    end

    begin
      uri = URI.parse(location)
      return uri.request_uri if uri.host.present? && uri.host == request.host
    rescue URI::InvalidURIError
    end
    "/"
  end

  # First MojoAuth login: provision a legacy user record. The account has no
  # usable password (random throwaway) — email possession is the credential.
  # skip_activation_mail suppresses the legacy "activate your account" email;
  # the user is activated immediately below.
  def build_user_from_email(email)
    user = User.new
    user.email = email
    user.login = login_from_email(email)
    user.first_name = params[:first_name].presence if params[:first_name].present?
    user.last_name = params[:last_name].presence if params[:last_name].present?
    password = SecureRandom.hex(10)
    user.password = password
    user.password_confirmation = password
    user.ip_address = request.remote_ip
    user.skip_activation_mail = true
    user
  end

  def login_from_email(email)
    base = email.to_s.split("@").first.to_s.downcase.gsub(/[^a-z0-9\-]/, "")
    base = "user#{base}" if base.blank? || base !~ /\A[a-z]/
    base = base[0, 36]
    base = base.ljust(3, "0") if base.length < 3

    # Two addresses can sanitize to the same handle (john.doe / johndoe), so
    # walk a numeric suffix until the handle is free.
    candidate = base
    n = 1
    while User.where(login: candidate).exists?
      n += 1
      candidate = "#{base}#{n}"
    end
    candidate
  end
end
