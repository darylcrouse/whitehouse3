class VotesController < ApplicationController
  before_action :require_login

  def create
    priority = Priority.find(params[:priority_id].to_i)
    change = priority.changes.find(params[:change_id])
    change.vote(current_user, params[:value].to_i)
    redirect_to priority_change_path(priority, change), notice: "Your vote was recorded."
  end
end
