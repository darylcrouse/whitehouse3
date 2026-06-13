class AdminController < ApplicationController
  before_action :admin_required

  def random_user
    user = if User.connection.adapter_name == 'PostgreSQL'
             User.active.order('RANDOM()').first
           else
             User.active.order('RAND()').first
           end
    
    self.current_user = user
    flash[:notice] = t('admin.impersonate', user_name: user.name)
    redirect_to user
  end

  def picture
    @page_title = t('admin.logo', government_name: current_government.name)
  end

  def picture_save
    @government = current_government
    
    if @government.update(government_params)
      flash[:notice] = t('pictures.success')
      redirect_to action: :picture
    else
      render :picture
    end
  end

  def fav_icon
    @page_title = t('admin.fav_icon', government_name: current_government.name)
  end

  def fav_icon_save
    @government = current_government
    
    if @government.update(government_params)
      flash[:notice] = t('pictures.success')
      redirect_to action: :fav_icon
    else
      render :fav_icon
    end
  end

  def buddy_icon
    @page_title = t('admin.buddy_icon', government_name: current_government.name)
  end

  def buddy_icon_save
    @government = current_government
    
    if @government.update(government_params)
      flash[:notice] = t('pictures.success')
      redirect_to action: :buddy_icon
    else
      render :buddy_icon
    end
  end

  private

  def government_params
    params.require(:government).permit(:your_permitted_attributes)
  end
end
