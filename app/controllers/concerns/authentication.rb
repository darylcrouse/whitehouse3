module Authentication
  extend ActiveSupport::Concern

  included do
    # Always resume an existing session (so current_user works on public pages),
    # but never force a login globally. Controllers require auth per-action via
    # `before_action :require_login` (defined in ApplicationController).
    before_action :resume_session
    helper_method :authenticated?
  end

  class_methods do
    # Retained for compatibility with Rails' generated Sessions/Passwords
    # controllers. Authentication isn't required globally here, so this is a
    # no-op — every action already allows unauthenticated access.
    def allow_unauthenticated_access(**options)
    end
  end

  private
    def authenticated?
      Current.session.present?
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to login_path, alert: "Please sign in to continue."
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session&.destroy
      cookies.delete(:session_id)
    end
end
