module Admin
  class UsersController < BaseController
    before_action :set_user, only: %i[make_admin suspend]

    def index
      @users = User.order(created_at: :desc).page_list(params[:page])
    end

    def make_admin
      @user.update(is_admin: !@user.is_admin?)
      redirect_to admin_users_path, notice: "#{@user.name} admin status updated."
    end

    def suspend
      new_status = @user.status == "suspended" ? "active" : "suspended"
      @user.update(status: new_status)
      redirect_to admin_users_path, notice: "#{@user.name} is now #{new_status}."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end
  end
end
