module Admin
  class GovernmentsController < BaseController
    def edit
      @government = Government.current
    end

    def update
      @government = Government.current
      if @government.update(government_params)
        redirect_to edit_admin_government_path, notice: "Site settings saved."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def government_params
      params.require(:government).permit(:name, :tagline, :mission, :prompt,
        :tags_name, :briefing_name, :currency_name, :currency_short_name,
        :homepage, :is_tags, :is_branches, :official_user_id)
    end
  end
end
