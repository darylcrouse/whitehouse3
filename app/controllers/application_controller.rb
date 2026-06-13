class ApplicationController < ActionController::Base
  include Authentication

  # The site is public to read; the Authentication concern resumes any existing
  # session on every request. Individual actions opt into requiring a login via
  # `before_action :require_login`.
  before_action :set_government

  helper_method :current_user, :logged_in?

  private

  def set_government
    Current.government = Government.current
  end

  def current_user
    Current.user
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if logged_in?
    session[:return_to_after_authenticating] = request.url
    redirect_to login_path, alert: "Please sign in to continue."
  end

  def require_admin
    require_login
    return if performed?
    redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
  end
end
