module Admin
  class PrioritiesController < BaseController
    def index
      @priorities = Priority.order(created_at: :desc).page_list(params[:page])
    end

    def destroy
      Priority.find(params[:id]).destroy
      redirect_to admin_priorities_path, notice: "Priority deleted."
    end
  end
end
