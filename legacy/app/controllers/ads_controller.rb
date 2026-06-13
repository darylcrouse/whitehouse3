class AdsController < ApplicationController
  before_action :get_priority
  before_action :login_required, only: [:new, :create, :preview, :skip]

  def index
    @ads = @priority.ads.by_recently_created.page(params[:page]).per(params[:per_page])
    @page_title = t('ads.index.title', priority_name: @priority.name)
    
    respond_to do |format|
      format.html { redirect_to priority_path(@priority) }
      format.xml { render xml: @ads.to_xml(include: [:user, :priority], except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @ads.to_json(include: [:user, :priority], except: NB_CONFIG['api_exclude_fields']) }
    end
  end

  def show
    @ad = @priority.ads.find(params[:id])
    @page_title = t('ads.show.title', priority_name: @priority.name)
    @activities = @ad.activities.active.by_recently_created.page(params[:page]).per(params[:per_page])
    
    respond_to do |format|
      format.html
      format.xml { render xml: @ad.to_xml(include: [:user, :priority], except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @ad.to_json(include: [:user, :priority], except: NB_CONFIG['api_exclude_fields']) }
    end
  end

  def new
    if @priority.position < 26
      flash[:error] = t('ads.new.top25error')
      redirect_to @priority
      return
    end
    
    @page_title = t('ads.new.title', priority_name: @priority.name)
    @ad = @priority.ads.new(user: current_user, cost: 1, show_ads_count: 100)
  end

  def create
    @ad = @priority.ads.new(ad_params.merge(user: current_user))
    
    if @ad.save
      flash[:notice] = t('ads.new.success', priority_name: @priority.name)
      redirect_to priority_ad_path(@priority, @ad)
    else
      render :new
    end
  end

  def preview
    @ad = @priority.ads.new(ad_params.merge(user: current_user))
    
    respond_to do |format|
      format.js
    end
  end

  def skip
    @ad = @priority.ads.find(params[:id])
    @ad.vote(current_user, -2, request)
    @priority.reload
    
    respond_to do |format|
      format.js
    end
  end

  private

  def get_priority
    @priority = Priority.find(params[:priority_id])
    @endorsement = @priority.endorsements.active.find_by(user_id: current_user.id) if logged_in?
  end

  def ad_params
    params.require(:ad).permit(:your_permitted_attributes)
  end
end
