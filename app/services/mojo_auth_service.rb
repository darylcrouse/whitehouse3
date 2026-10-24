# frozen_string_literal: true
require "net/http"
require "json"

# Server-side integration with MojoAuth passwordless authentication.
#
# Credentials live in config/mojoauth.yml (git-ignored) and can be overridden
# with MOJOAUTH_API_KEY / MOJOAUTH_API_SECRET env vars. Development and test
# environments use the sandbox credentials; production uses live ones.
#
# Token verification uses MojoAuth's REST API:
#   POST https://api.mojoauth.com/token/verify
#   x-api-key: <api key>   /   Authorization: Bearer <access token>
#   => { "isValid" => true, "user" => { "identifier" => "email or phone", ... } }
class MojoAuthService
  API_BASE = "https://api.mojoauth.com"

  class << self
    def config
      @config ||= load_config
    end

    # Allows tests / console to pick up edited credentials without a reboot.
    def reset_config!
      @config = load_config
    end

    def enabled?
      api_key.present?
    end

    def api_key
      config["api_key"]
    end

    def api_secret
      config["api_secret"]
    end

    # Verifies a MojoAuth access token with the API. Returns the user
    # identifier (email/phone) when the token is valid, nil otherwise.
    def verify_access_token(token)
      return nil if !enabled? || token.to_s.strip.empty?

      uri = URI("#{API_BASE}/token/verify")
      request = Net::HTTP::Post.new(uri)
      request["x-api-key"] = api_key
      request["Authorization"] = "Bearer #{token}"
      request["Accept"] = "application/json"
      request.body = ""

      response = Net::HTTP.start(uri.hostname, uri.port,
                                 use_ssl: true,
                                 open_timeout: 5,
                                 read_timeout: 10) { |http| http.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[mojoauth] token/verify HTTP #{response.code}: #{response.body.to_s[0, 200]}")
        return nil
      end

      data = JSON.parse(response.body)
      return nil unless data.is_a?(Hash) && data["isValid"]

      data.dig("user", "identifier").presence
    rescue JSON::ParserError => e
      Rails.logger.warn("[mojoauth] token/verify parse error: #{e.message}")
      nil
    rescue StandardError => e
      Rails.logger.warn("[mojoauth] token/verify error: #{e.class}: #{e.message}")
      nil
    end

    # --- email OTP, driven by our own form -------------------------------
    #
    # The hosted widget insists on a WebAuthn (passkey) enrolment step after
    # the OTP whenever the project has webauthn enabled, and that step cannot
    # work on an insecure origin (plain http on a LAN address) - the button
    # silently does nothing. These two calls run the same OTP flow server
    # side, so the browser never touches the passkey code path and the API
    # key never reaches the client.
    #
    # Returns [status_code, parsed_body]. Never raises for HTTP failures.
    def request_email_otp(email)
      mojo_post("/users/emailotp?language=en", { email: email.to_s.strip.downcase })
    end

    def verify_email_otp(state_id, otp)
      mojo_post("/users/emailotp/verify", { state_id: state_id.to_s, otp: otp.to_s.strip })
    end

    def mojo_post(path, body)
      return [0, {}] if !enabled?

      uri = URI("#{API_BASE}#{path}")
      request = Net::HTTP::Post.new(uri)
      request["X-API-Key"] = api_key
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request.body = body.to_json

      response = Net::HTTP.start(uri.hostname, uri.port,
                                 use_ssl: true,
                                 open_timeout: 5,
                                 read_timeout: 10) { |http| http.request(request) }

      parsed = begin
        JSON.parse(response.body.to_s)
      rescue JSON::ParserError
        {}
      end
      [response.code.to_i, parsed]
    rescue StandardError => e
      Rails.logger.warn("[mojoauth] #{path} error: #{e.class}: #{e.message}")
      [0, {}]
    end

    private

    def load_config
      file = Rails.root.join("config", "mojoauth.yml")
      section = if File.exist?(file)
                  (YAML.load_file(file)[Rails.env.production? ? "production" : "test"] || {})
                else
                  {}
                end
      env = {
        "api_key" => ENV["MOJOAUTH_API_KEY"],
        "api_secret" => ENV["MOJOAUTH_API_SECRET"]
      }.reject { |_k, v| v.to_s.strip.empty? }
      section.merge(env)
    end
  end
end
