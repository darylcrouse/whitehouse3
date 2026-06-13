class ActivitiesController < ApplicationController
  before_action :admin_required, only: [:edit, :update]
  before_action :login_required, only: [:destroy, :undelete]

  def index
    if request.format != 'html'
      @activities = Activity.active.by_recently_created.page(params[:page]).per(params[:per_page])
    end
    
    respond_to do |format|
      format.html { redirect_to news_activities_path }
      format.xml { render xml: @activities.to_xml(include: [:user, :comments], except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @activities.to_json(include: [:user, :comments], except: NB_CONFIG['api_exclude_fields']) }
    end
  end

  def show
    @activity = Activity.find(params[:id])
    
    respond_to do |format|
      format.html { redirect_to activity_comments_path(@activity) }
      format.xml { render xml: @activity.to_xml(include: :user, except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @activity.to_json(include: :user, except: NB_CONFIG['api_exclude_fields']) }
    end
  end

  def unhide
    @activity = Activity.find(params[:id])
    
    respond_to do |format|
      format.js { render 'unhide', locals: { activity: @activity } }
    end
  end

  def update
    @activity = Activity.find(params[:id])

    respond_to do |format|
      if @activity.update(activity_params)
        flash[:notice] = 'Activity was successfully updated.'
        format.html { redirect_to @activity }
        format.xml  { head :ok }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @activity = Activity.find(params[:id])
    access_denied unless current_user.is_admin? || @activity.user_id == current_user.id
    @activity.delete!
    
    respond_to do |format|
      format.html { redirect_to activities_path }
      format.js { render 'destroy', locals: { activity: @activity } }
    end
  end

  def undelete
    @activity = Activity.find(params[:id])
    @activity.undelete!
    
    respond_to do |format|
      format.html { redirect_to activities_path }
    end
  end

  private

  def activity_params
    params.require(:activity).permit(:your_permitted_attributes)
  end
end
