class ChangesController < ApplicationController
  before_action :require_login, only: %i[new create approve decline]
  before_action :set_priority
  before_action :set_change, only: %i[show approve decline]

  def index
    @changes = @priority.change_proposals.newest
  end

  def show
    @votes = @change.votes.includes(:user)
  end

  def new
    @change = @priority.change_proposals.new(type: "ChangeName")
  end

  def create
    @change = @priority.change_proposals.new(change_params)
    @change.user = current_user
    @change.status = "sent"
    if @change.save
      redirect_to priority_change_path(@priority, @change), notice: "Change proposed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    @change.approve! if current_user.admin?
    redirect_to priority_change_path(@priority, @change), notice: "Change approved."
  end

  def decline
    @change.decline! if current_user.admin?
    redirect_to priority_change_path(@priority, @change), notice: "Change declined."
  end

  private

  def set_priority
    @priority = Priority.find(params[:priority_id].to_i)
  end

  def set_change
    @change = @priority.change_proposals.find(params[:id])
  end

  def change_params
    params.require(:change).permit(:content, :type)
  end
end
