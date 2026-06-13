class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_activity

  def create
    @comment = @activity.comments.new(comment_params)
    @comment.user = current_user
    if @comment.save
      redirect_back fallback_location: activity_path(@activity), notice: "Comment added."
    else
      redirect_back fallback_location: activity_path(@activity), alert: "Comment can't be blank."
    end
  end

  def destroy
    comment = @activity.comments.find(params[:id])
    comment.destroy if current_user.admin? || comment.user_id == current_user.id
    redirect_back fallback_location: activity_path(@activity), notice: "Comment removed."
  end

  private

  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
