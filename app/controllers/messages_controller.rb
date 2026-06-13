class MessagesController < ApplicationController
  before_action :require_login
  before_action :set_message, only: %i[show destroy]

  def index
    @messages = Message.inbox(current_user)
  end

  def sent
    @messages = Message.sent(current_user)
    render :index
  end

  def show
    @message.mark_read! if @message.recipient_id == current_user.id
  end

  def new
    @message = Message.new(recipient_id: params[:to])
  end

  def create
    @message = Message.new(message_params)
    @message.sender = current_user
    if @message.save
      redirect_to messages_path, notice: "Message sent."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @message.update(deleted_at: Time.current) if @message.recipient_id == current_user.id
    redirect_to messages_path, notice: "Message deleted."
  end

  private

  def set_message
    @message = Message.where("sender_id = :id OR recipient_id = :id", id: current_user.id).find(params[:id])
  end

  def message_params
    params.require(:message).permit(:recipient_id, :title, :content)
  end
end
