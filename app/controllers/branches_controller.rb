class BranchesController < ApplicationController
  before_action :require_login, only: %i[new create edit update destroy]
  before_action :set_branch, only: %i[show priorities users edit update destroy]

  def index
    @branches = Branch.most_active
  end

  def show
    @members = @branch.users.active.most_active.limit(20)
    @priorities = Priority.published.joins(endorsements: :user)
                          .where(users: { branch_id: @branch.id })
                          .group("priorities.id").order("priorities.score desc").limit(25)
  end

  def priorities
    @priorities = Priority.published.joins(endorsements: :user)
                          .where(users: { branch_id: @branch.id })
                          .group("priorities.id").order("priorities.score desc")
                          .page_list(params[:page])
    render :show
  end

  def users
    @members = @branch.users.active.most_active.page_list(params[:page])
  end

  def new
    @branch = Branch.new
  end

  def create
    @branch = Branch.new(branch_params)
    if @branch.save
      redirect_to @branch, notice: "Branch created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @branch.update(branch_params)
      redirect_to @branch, notice: "Branch updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @branch.destroy if current_user.admin?
    redirect_to branches_path, notice: "Branch removed."
  end

  private

  def set_branch
    @branch = Branch.find(params[:id])
  end

  def branch_params
    params.require(:branch).permit(:name, :description)
  end
end
