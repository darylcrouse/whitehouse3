# Rails 8 port of the original ApplicationController.
#
# The mechanical port had dropped a number of methods that the rest of the app
# (views, filters, controllers) still relies on — the before_action filters,
# the view-helper accessors (current_tags, current_branches, ...), layout
# selection and the FaceboxRender plugin hook. Those are restored here.
class ApplicationController < ActionController::Base
  helper_method :facebook_session, :government_cache, :current_partner,
                :current_user_endorsements, :current_priority_ids,
                :current_following_ids, :current_ignoring_ids,
                :current_following_facebook_uids, :current_government,
                :current_tags, :current_branches, :is_robot?, :js_help,
                :logged_in?, :current_user, :facebook_uid

  rescue_from ActionController::InvalidAuthenticityToken, with: :bad_token
  rescue_from Facebooker::Session::SessionExpired, with: :fb_session_expired

  before_action :check_subdomain
  before_action :load_actions_to_publish, unless: :is_robot?
  before_action :check_facebook, unless: :is_robot?
  before_action :check_blast_click, unless: :is_robot?
  before_action :check_priority, unless: :is_robot?
  before_action :check_referral, unless: :is_robot?
  before_action :check_suspension, unless: :is_robot?
  before_action :update_loggedin_at, unless: :is_robot?

  layout :get_layout

  protect_from_forgery

  # --- layout ---------------------------------------------------------------

  def get_layout
    return false if !is_robot? && !current_government
    return 'basic' if !current_government
    current_government.layout
  end

  # --- government / user context helpers ------------------------------------

  def current_government
    @current_government ||= Rails.cache.fetch('government', expires_in: 15.minutes) do
      government = Government.last
      government.update_counts if government
      government
    end
    Government.current = @current_government if @current_government
    @current_government
  end

  def government_cache
    Rails.cache
  end

  def current_partner
    return nil if request.subdomains.empty? ||
                  request.host == current_government&.base_url ||
                  request.subdomains.first == 'dev'
    @current_partner ||= Partner.find_by(short_name: request.subdomains.first)
  end

  def current_user_endorsements
    @current_user_endorsements ||= current_user.endorsements.active.by_position.includes(:priority).page(session[:endorsement_page]).per(25)
  end

  def current_priority_ids
    return [] unless logged_in? && current_user.endorsements_count.positive?
    @current_priority_ids ||= current_user.endorsements.active_and_inactive.pluck(:priority_id)
  end

  def current_following_ids
    return [] unless logged_in? && current_user.followings_count.positive?
    @current_following_ids ||= current_user.followings.up.pluck(:other_user_id)
  end

  def current_following_facebook_uids
    return [] unless logged_in? && current_user.followings_count.positive? && current_user.has_facebook?
    @current_following_facebook_uids ||= current_user.followings.up.map { |f| f.other_user.facebook_uid }.compact
  end

  def current_ignoring_ids
    return [] unless logged_in? && current_user.ignorings_count.positive?
    @current_ignoring_ids ||= current_user.followings.down.pluck(:other_user_id)
  end

  def current_branches
    return [] unless current_government.is_branches?
    Branch.all_cached
  end

  def current_tags
    return [] unless current_government.is_tags?
    @current_tags ||= Rails.cache.fetch('Tag.by_endorsers_count.all') { Tag.by_endorsers_count.all }
  end

  # --- filters --------------------------------------------------------------

  def load_actions_to_publish
    @user_action_to_publish = flash[:user_action_to_publish]
    flash[:user_action_to_publish] = nil
  end

  def check_suspension
    return unless logged_in? && current_user && current_user.suspended?
    current_user.forget_me
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "This account has been suspended."
    redirect_back_or_default('/')
  end

  def check_priority
    return unless logged_in? && session[:priority_id]
    @priority = Priority.find_by(id: session[:priority_id])
    @value = session[:value].to_i
    if @priority
      @value == 1 ? @priority.endorse(current_user, request, current_partner, @referral) : @priority.oppose(current_user, request, current_partner, @referral)
    end
    session[:priority_id] = nil
    session[:value] = nil
  end

  def update_loggedin_at
    return unless logged_in? && (current_user.loggedin_at.nil? || Time.current > current_user.loggedin_at + 30.minutes)
    current_user.update_column(:loggedin_at, Time.current)
  end

  def check_blast_click
    if params[:b].present? && params[:b].length > 2
      @blast = Blast.find_by(code: params[:b])
      if @blast && !logged_in?
        self.current_user = @blast.user
        @blast.increment!(:clicks_count)
      end
      redirect_to request.path_info.split('?').first
    end
  end

  def check_subdomain
    return if current_government
    redirect_to controller: "install"
  end

  def check_referral
    @referral = params[:referral_id].present? ? User.find_by(id: params[:referral_id]) : nil
  end

  def check_facebook
    return unless Facebooker.api_key && logged_in? && facebook_session && !current_user.has_facebook?
    return if facebook_session.user.uid == 55714215 && current_user.id != 1
    @user = User.find(current_user.id)
    if @user.update_with_facebook(facebook_session)
      @user.activate! unless @user.activated?
      @current_user = User.find(current_user.id)
      flash.now[:notice] = t('facebook.synced', government_name: current_government.name)
    end
  end

  # --- helpers exposed to views --------------------------------------------

  def is_robot?
    request.format.rss? ||
      params[:controller] == 'pictures' ||
      request.user_agent.to_s =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
  end

  def no_facebook?
    Facebooker.api_key.blank? || is_robot?
  end

  def js_help
    JavaScriptHelper.instance
  end

  class JavaScriptHelper
    include Singleton
    include ActionView::Helpers::JavaScriptHelper
  end

  # --- error handling -------------------------------------------------------

  def bad_token
    flash[:error] = t('application.bad_token')
    respond_to do |format|
      format.html { redirect_back fallback_location: '/' }
      format.any  { redirect_to(request.referrer || '/') }
    end
  end

  def fb_session_expired
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:error] = t('application.fb_session_expired')
    respond_to do |format|
      format.html { redirect_back fallback_location: '/' }
      format.any  { redirect_to(request.referrer || '/') }
    end
  end

  # --- legacy Facebook hook (Facebook Platform v1 is retired) ---------------

  def facebook_session
    nil
  end

  def facebook_uid
    nil
  end

  # facebox_render plugin was retired with the Rails 2 stack; render inline
  # instead of into a facebox overlay.
  def render_to_facebox(options = {})
    case
    when options.blank?
      render
    when options[:template]
      render(template: options[:template], layout: false)
    when options[:partial]
      render(partial: options[:partial], layout: false)
    when options[:html]
      render(html: options[:html], layout: false)
    else
      render(options)
    end
  end

  # --- authentication (stateful_authentication-style) -----------------------

  def logged_in?
    !!current_user
  end

  # Accesses the current user from the session.
  # Future calls avoid the database because nil is not equal to false.
  def current_user
    @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie) unless @current_user == false
  end

  # Store the given user id in the session.
  def current_user=(new_user)
    session[:user_id] = new_user ? new_user.id : nil
    @current_user = new_user || false
  end

  # Check if the user is authorized
  #
  # Override this method in your controllers if you want to restrict access
  # to only a few actions or if you want to check if the user
  # has the correct rights.
  def authorized?
    logged_in?
  end

  # Filter method to enforce a login requirement.
  #
  # To require logins for all actions, use this in your controllers:
  #
  #   before_action :login_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_action :login_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_action :login_required
  #
  def login_required
    authorized? || access_denied
  end

  def admin_required
    (logged_in? and current_user.is_admin?) || access_denied
  end

  def current_user_required
    access_denied unless logged_in? and (current_user.id == params[:id].to_i or current_user.is_admin?)
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized to access the requested action.
  def access_denied
    flash[:error] = I18n.t('sessions.please_login')
    respond_to do |format|
      format.html do
        store_location
        redirect_to new_session_path
      end
      format.js do
        store_previous_location
        render_to_facebox(:template => "sessions/new")
      end
      format.any do
        request_http_basic_authentication 'Web Password'
      end
    end
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.fullpath
  end

  def store_previous_location
    session[:return_to] = request.env['HTTP_REFERER'] || '/'
  end

  def get_previous_location(default = '/')
    location = session[:return_to] || default
    session[:return_to] = nil
    location
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default = '/')
    redirect_to(get_previous_location(default))
  end

  # Called from #current_user. First attempt to login by the user id stored
  # in the session.
  def login_from_session
    if session[:user_id]
      u = User.find_by_id(session[:user_id])
      self.current_user = u
    end
  end

  # Called from #current_user. Then try to login via Facebook (retired — the
  # facebook_session stub returns nil, so this is a no-op).
  def login_from_facebook
    if facebook_session
      if u = User.find_by_facebook_uid(facebook_session.user.uid)
        return u
      end
      u = User.create_from_facebook(facebook_session, current_partner, request)
      if u
        session[:goal] = 'signup'
        return u
      else
        return false
      end
    end
  end

  def login_from_basic_auth
    authenticate_with_http_basic do |email, password|
      self.current_user = User.authenticate(email, password)
    end
  end

  # Called from #current_user. Attempt to login by an expiring token in the cookie.
  def login_from_cookie
    user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
    if user && user.remember_token?
      cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
      self.current_user = user
    else
      return false
    end
  end
end
