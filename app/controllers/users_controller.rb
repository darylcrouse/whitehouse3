class UsersController < ApplicationController
  before_action :require_login, only: %i[follow unfollow]
  before_action :set_user, only: %i[show priorities points activities follow unfollow]

  def index
    @tab = params[:tab].presence || "active"
    @users = case @tab
             when "newest" then User.active.newest
             when "score"  then User.active.by_score
             else User.active.most_active
             end.page_list(params[:page])
  end

  def show
    @priorities = @user.endorsed_priorities.merge(Endorsement.active)
                       .order("endorsements.position asc").limit(10)
    @activities = @user.activities.feed.limit(20)
  end

  def priorities
    @priorities = @user.endorsed_priorities.merge(Endorsement.active)
                       .order("endorsements.position asc").page_list(params[:page])
  end

  def points
    @points = @user.points.published.newest.page_list(params[:page])
  end

  def activities
    @activities = @user.activities.feed.page_list(params[:page])
  end

  # Signup ----------------------------------------------------------------------

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.status = "active"
    if @user.save
      ActivityUserNew.create(user: @user)
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to #{Government.current.name}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def follow
    current_user.followings.find_or_create_by(other_user_id: @user.id) { |f| f.value = 1 }
    redirect_back fallback_location: user_path(@user), notice: "You are now following #{@user.name}."
  end

  def unfollow
    current_user.followings.where(other_user_id: @user.id).destroy_all
    redirect_back fallback_location: user_path(@user), notice: "You stopped following #{@user.name}."
  end

  private

  def set_user
    @user = User.find_by!(login: params[:id])
  end

  def user_params
    params.require(:user).permit(:login, :email_address, :password, :password_confirmation,
                                 :first_name, :last_name, :bio, :website, :city, :state)
  end
end
