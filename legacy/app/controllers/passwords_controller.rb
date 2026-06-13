class PasswordsController < ApplicationController
  layout "sessions"
  ssl_required :new, :create, :edit, :update, :reset

  before_action :find_password, only: [:edit, :update, :reset]
  before_action :login_from_token, only: [:edit, :update]
  before_action :login_required, only: [:new, :create]

  def new
    @page_title = t('passwords.new.title', government_name: current_government.name)
  end

  def create
    @user = User.find_by(email: params[:user][:email])
    if @user
      PasswordMailer.reset_password(@user).deliver_now
      flash[:notice] = t('passwords.sent', government_name: current_government.name)
      redirect_to login_path
    else
      flash[:error] = t('passwords.invalid', government_name: current_government.name)
      render action: "new"
    end
  end

  def edit
    @page_title = t('passwords.edit.title', government_name: current_government.name)
  end

  def update
    new_password = params[:user][:password]
    new_password_confirmation = params[:user][:password_confirmation]

    if @user.update(password: new_password, password_confirmation: new_password_confirmation)
      flash[:notice] = t('passwords.success')
      redirect_to login_path
    else
      flash[:error] = t('passwords.invalid', government_name: current_government.name)
      render action: "edit"
    end
  end

  def reset
    raise "Password token expired" if @password.expired?
    @page_title = t('passwords.new.title', government_name: current_government.name)
    render
  end

  private

  def find_password
    @password = Password.find_by(param: params[:id])
    raise "Invalid password" unless @password
  end

  def login_from_token
    session[:user_id] = @password.user_id
    @user = User.find(session[:user_id])
    raise "Invalid user" unless @user
  end
end
