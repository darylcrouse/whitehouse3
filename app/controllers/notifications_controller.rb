class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = current_user.notifications.newest.page_list(params[:page])
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current, status: "read")
    redirect_to notifications_path, notice: "All notifications marked read."
  end
end
