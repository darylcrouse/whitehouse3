# Passwordless login endpoint for the MojoAuth widget flow.
#
# The browser completes the MojoAuth sign-in (email OTP / magic link) and then
# POSTs the resulting access token here. We verify the token server-side via
# MojoAuthService, map it to a legacy User (creating one on first login), and
# establish the app's normal session. The verified token IS the credential for
# this endpoint, so CSRF token verification is skipped (OAuth-style endpoint).
class MojoAuthSessionsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    token = params[:access_token].to_s
    identifier = MojoAuthService.verify_access_token(token)

    if identifier.blank?
      return render json: { ok: false, error: t("sessions.create.failed") },
                    status: :unauthorized
    end

    email = identifier.to_s.strip.downcase
    user = User.where("LOWER(email) = ?", email).first

    if user.nil?
      user = build_user_from_email(email)
      unless user.save
        return render json: { ok: false, error: user.errors.full_messages.to_sentence },
                      status: :unprocessable_entity
      end
    end

    if user.deleted? || user.suspended?
      return render json: { ok: false, error: t("sessions.create.failed") },
                    status: :forbidden
    end

    # MojoAuth has already proven ownership of this email address, so any
    # legacy activation state can be completed now.
    user.activate! if user.pending? || user.passive?
    user.update_attribute(:loggedin_at, Time.now) if user.respond_to?(:loggedin_at)

    self.current_user = user
    current_user.remember_me unless current_user.remember_token?
    cookies[:auth_token] = { value: current_user.remember_token,
                             expires: current_user.remember_token_expires_at }

    render json: { ok: true, redirect: "/" }
  rescue StandardError => e
    Rails.logger.error("[mojoauth] login failed: #{e.class}: #{e.message}")
    render json: { ok: false, error: t("sessions.create.failed") },
           status: :internal_server_error
  end

  private

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
    base = base[0, 40]
    base = base.ljust(3, "0") if base.length < 3
    base
  end
end
