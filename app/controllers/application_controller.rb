class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include FaceboxRender

  require_dependency "activity.rb"
  require_dependency "blast.rb"
  require_dependency "relationship.rb"
  require_dependency "capital.rb"

  rescue_from ActionController::InvalidAuthenticityToken, with: :bad_token
  rescue_from Facebooker::Session::SessionExpired, with: :fb_session_expired

  helper_method :facebook_session, :government_cache, :current_partner, :current_user_endorsements, :current_priority_ids, :current_following_ids, :current_ignoring_ids, :current_following_facebook_uids, :current_government, :current_tags, :current_branches, :facebook_session, :is_robot?, :js_help

  before_action :check_subdomain
  before_action :set_facebook_session, unless: :no_facebook?
  before_action :load_actions_to_publish, unless: :is_robot?
  before_action :check_facebook, unless: :is_robot?
  before_action :check_blast_click, unless: :is_robot?
  before_action :check_priority, unless: :is_robot?
  before_action :check_referral, unless: :is_robot?
  before_action :check_suspension, unless: :is_robot?
  before_action :update_loggedin_at, unless: :is_robot?

  layout :get_layout

  protect_from_forgery

  private

  def get_layout
    return false if !is_robot? && !current_government
    return "basic" if !current_government
    current_government.layout
  end

  def current_government
    @current_government ||= Rails.cache.fetch('government', expires_in: 15.minutes) do
      government = Government.last
      government.update_counts if government
      government
    end
    Government.current = @current_government
    @current_government
  end

  def current_partner
    return nil if request.subdomains.empty? || request.host == current_government.base_url || request.subdomains.first == 'dev'
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

  def is_robot?
    request.format == :rss || params[:controller] == 'pictures' || request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
  end

  def no_facebook?
    Facebooker.api_key.blank? || is_robot?
  end

  def bad_token
    flash[:error] = t('application.bad_token')
    respond_to do |format|
      format.html { redirect_back fallback_location: '/' }
      format.js { redirect_from_facebox(request.referrer || '/') }
    end
  end

  def fb_session_expired
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:error] = t('application.fb_session_expired')
    respond_to do |format|
      format.html { redirect_back fallback_location: '/' }
      format.js { redirect_from_facebox(request.referrer || '/') }
    end
  end

  def js_help
    JavaScriptHelper.instance
  end

  class JavaScriptHelper
    include Singleton
    include ActionView::Helpers::JavaScriptHelper
  end
end

module FaceboxRender
  def render_to_facebox(options = {})
    options[:template] = "#{default_template_name}" if options.empty?

    action_string = render
render :update do |page|
  page << "jQuery.facebox(#{action_string.to_json})" if options[:action]
  page << "jQuery.facebox(#{template_string.to_json})" if options[:template]
  page << "jQuery.facebox(#{render(partial: options[:partial]).to_json})" if options[:partial]
  page << "jQuery.facebox(#{options[:html].to_json})" if options[:html]

  if options[:msg]
    page << "jQuery('#facebox .content').prepend('<div class=\"message\">#{options[:msg]}</div>')"
  end
  page << render(partial: "shared/javascripts_reloadable")

  yield(page) if block_given?
end
