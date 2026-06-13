class PrioritiesController < ApplicationController
  before_action :require_login, only: %i[new create edit update destroy endorse oppose unendorse]
  before_action :set_priority, only: %i[show edit update destroy endorse oppose unendorse
                                         points documents activities endorsers opposers]

  # The leaderboard. Default tab is "top"; other tabs reuse the same view.
  def index
    @tab = "top"
    @priorities = Priority.published.top_rank.page_list(params[:page])
    render :index
  end

  def top
    @tab = "top"
    @priorities = Priority.published.top_rank.page_list(params[:page])
    render :index
  end

  def rising
    @tab = "rising"
    @priorities = Priority.published.rising.page_list(params[:page])
    render :index
  end

  def falling
    @tab = "falling"
    @priorities = Priority.published.falling.page_list(params[:page])
    render :index
  end

  def controversial
    @tab = "controversial"
    @priorities = Priority.published.controversial.page_list(params[:page])
    render :index
  end

  def newest
    @tab = "newest"
    @priorities = Priority.published.newest.page_list(params[:page])
    render :index
  end

  def finished
    @tab = "finished"
    @priorities = Priority.finished.newest.page_list(params[:page])
    render :index
  end

  def untagged
    @tab = "untagged"
    @priorities = Priority.published.untagged.page_list(params[:page])
    render :index
  end

  def random
    @tab = "random"
    @priorities = Priority.published.order(Arel.sql("RANDOM()")).limit(25)
    render :index
  end

  def yours
    require_login
    return if performed?
    @tab = "yours"
    @priorities = current_user.endorsed_priorities.merge(Endorsement.active).order("endorsements.position asc")
    render :index
  end

  def show
    @points_for     = @priority.points.published.supporting.by_helpfulness.limit(10)
    @points_against = @priority.points.published.opposing.by_helpfulness.limit(10)
    @documents      = @priority.documents.published.newest.limit(5)
    @activities     = @priority.activities.feed.limit(20)
    @related        = @priority.related
  end

  def new
    @priority = Priority.new
  end

  def create
    @priority = Priority.new(priority_params)
    @priority.user = current_user
    @priority.ip_address = request.remote_ip
    if @priority.save
      @priority.issue_list = params[:issue_list] if params[:issue_list].present?
      @priority.save
      @priority.endorse(current_user, request) # creator auto-endorses
      redirect_to @priority, notice: "Your priority was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @priority.update(priority_params)
      @priority.issue_list = params[:issue_list] if params.key?(:issue_list)
      @priority.save
      redirect_to @priority, notice: "Priority updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_owner_or_admin!
    return if performed?
    @priority.update(status: "deleted", deleted_at: Time.current)
    redirect_to priorities_path, notice: "Priority removed."
  end

  # Positions -------------------------------------------------------------------

  def endorse
    @priority.endorse(current_user, request)
    respond_to_position_change "You endorsed this priority."
  end

  def oppose
    @priority.oppose(current_user, request)
    respond_to_position_change "You opposed this priority."
  end

  def unendorse
    @priority.unendorse(current_user)
    respond_to_position_change "Removed from your priorities."
  end

  # Sub-listings ----------------------------------------------------------------

  def points
    @points = @priority.points.published.by_helpfulness.page_list(params[:page])
  end

  def documents
    @documents = @priority.documents.published.newest.page_list(params[:page])
  end

  def activities
    @activities = @priority.activities.feed.page_list(params[:page])
  end

  def endorsers
    @users = @priority.endorsements.active.endorsing.includes(:user).map(&:user)
  end

  def opposers
    @users = @priority.endorsements.active.opposing.includes(:user).map(&:user)
  end

  private

  def set_priority
    @priority = Priority.find(params[:id].to_i)
  end

  def priority_params
    params.require(:priority).permit(:name)
  end

  def authorize_owner_or_admin!
    return if current_user&.admin? || @priority.user_id == current_user&.id
    redirect_to @priority, alert: "Not authorized."
  end

  def respond_to_position_change(message)
    respond_to do |format|
      format.html { redirect_back fallback_location: @priority, notice: message }
      format.turbo_stream { redirect_back fallback_location: @priority, notice: message }
    end
  end
end
