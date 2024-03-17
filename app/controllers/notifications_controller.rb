class NotificationsController < ApplicationController
  before_action :login_required
  before_action :set_notification, only: [:show, :destroy]

  def authorized?
    current_user.is_admin? || @notification.recipient_id == current_user.id
  end

  def show
    respond_to do |format|
      format.html
      format.xml { render xml: @notification.to_xml(include: [:sender, :notifiable], except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @notification.to_json(include: [:sender, :notifiable], except: NB_CONFIG['api_exclude_fields']) }
    end
  end

  def destroy
    @notification.delete!
    respond_to do |format|
      format.html { redirect_to(controller: "inbox", action: "notifications") }
      format.js {
        render js: "document.getElementById('notification_#{@notification.id}').remove();"
      }
    end
  end

  private
    def set_notification
      @notification = Notification.find(params[:id])
    end
end
