class SettingsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(settings_params)
      redirect_to settings_path, notice: "Your settings were saved."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def settings_params
    permitted = params.require(:user).permit(:first_name, :last_name, :bio, :website,
                                             :city, :state, :branch_id, :email_address,
                                             :password, :password_confirmation)
    permitted.delete(:password) if permitted[:password].blank?
    permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
    permitted
  end
end
