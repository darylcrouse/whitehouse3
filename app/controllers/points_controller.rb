class PointsController < ApplicationController
  before_action :require_login, only: %i[new create edit update destroy quality unquality]
  before_action :set_priority, only: %i[index new create edit update destroy], if: -> { params[:priority_id] }
  before_action :set_point, only: %i[show edit update destroy quality unquality]

  def index
    if @priority
      @points = @priority.points.published.by_helpfulness.page_list(params[:page])
    else
      @points = Point.published.newest.page_list(params[:page])
    end
  end

  def show
    @point ||= Point.find(params[:id])
    @priority = @point.priority
  end

  def new
    @point = @priority.points.new(value: params[:value] || 1)
  end

  def create
    @point = @priority.points.new(point_params)
    @point.user = current_user
    if @point.save
      redirect_to priority_path(@priority, anchor: "points"), notice: "Your point was added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @point.update(point_params)
      redirect_to priority_path(@point.priority), notice: "Point updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @point.destroy if owner_or_admin?(@point)
    redirect_to priority_path(@point.priority), notice: "Point removed."
  end

  def quality
    rate(true)
  end

  def unquality
    rate(false)
  end

  private

  def rate(helpful)
    pq = current_user.point_qualities.find_or_initialize_by(point_id: @point.id)
    pq.value = helpful
    pq.save
    redirect_back fallback_location: priority_path(@point.priority),
                  notice: helpful ? "Marked helpful." : "Marked unhelpful."
  end

  def set_priority
    @priority = Priority.find(params[:priority_id].to_i)
  end

  def set_point
    @point = Point.find(params[:id])
  end

  def point_params
    params.require(:point).permit(:name, :content, :value, :website)
  end

  def owner_or_admin?(point)
    current_user&.admin? || point.user_id == current_user&.id
  end
end
