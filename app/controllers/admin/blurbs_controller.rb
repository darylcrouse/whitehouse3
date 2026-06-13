module Admin
  class BlurbsController < BaseController
    before_action :set_blurb, only: %i[edit update destroy]

    def index
      @blurbs = Blurb.order(:name)
    end

    def new
      @blurb = Blurb.new
    end

    def create
      @blurb = Blurb.new(blurb_params)
      if @blurb.save
        redirect_to admin_blurbs_path, notice: "Blurb created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @blurb.update(blurb_params)
        redirect_to admin_blurbs_path, notice: "Blurb updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @blurb.destroy
      redirect_to admin_blurbs_path, notice: "Blurb deleted."
    end

    private

    def set_blurb
      @blurb = Blurb.find(params[:id])
    end

    def blurb_params
      params.require(:blurb).permit(:name, :content)
    end
  end
end
