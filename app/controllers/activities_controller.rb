class ActivitiesController < ApplicationController
  before_action :set_activity, only: :show

  def index
    @activities = Activity.feed.includes(:user, :priority).page_list(params[:page])
  end

  def show
    @comments = @activity.comments.includes(:user)
  end

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end
end
