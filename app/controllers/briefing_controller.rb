class BriefingController < ApplicationController

  before_action :login_required, except: [:index, :contributors]

  def index
    redirect_to newest_points_url
  end
  
  def points
    @page_title = t('briefing.points.title')
    if current_user.endorsements_count > 0    
      if current_user.up_endorsements_count > 0 && current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.page(params[:page]).per(params[:per_page])
          .where("(priorities.id in (?) and priorities.up_points_count = 0) or 
                  (priorities.id in (?) and priorities.down_points_count = 0)",
                  current_user.endorsements.active_and_inactive.endorsing.pluck(:priority_id),
                  current_user.endorsements.active_and_inactive.opposing.pluck(:priority_id))
      elsif current_user.up_endorsements_count > 0
        @priorities = Priority.published.top_rank.page(params[:page]).per(params[:per_page])
          .where("priorities.id in (?) and priorities.up_points_count = 0",
                  current_user.endorsements.active_and_inactive.endorsing.pluck(:priority_id))
      elsif current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.page(params[:page]).per(params[:per_page])
          .where("priorities.id in (?) and priorities.down_points_count = 0",
                  current_user.endorsements.active_and_inactive.opposing.pluck(:priority_id))
      end
      @endorsements = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsements = current_user.endorsements.active.where(priority_id: @priorities.pluck(:id))
      end      
    else
      @priorities = nil
    end    
    respond_to do |format|
      format.html
      format.xml { render xml: @priorities }
      format.json { render json: @priorities }
    end 
  end

  def documents
    @page_title = t('briefing.documents.title')
    if current_user.endorsements_count > 0    
      if current_user.up_endorsements_count > 0 && current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.page(params[:page]).per(params[:per_page])
          .where("(priorities.id in (?) and priorities.up_documents_count = 0) or 
                  (priorities.id in (?) and priorities.down_documents_count = 0)",
                  current_user.endorsements.active_and_inactive.endorsing.pluck(:priority_id),
                  current_user.endorsements.active_and_inactive.opposing.pluck(:priority_id))
      elsif current_user.up_endorsements_count > 0
        @priorities = Priority.published.top_rank.page(params[:page]).per(params[:per_page])
          .where("priorities.id in (?) and priorities.up_documents_count = 0",
                  current_user.endorsements.active_and_inactive.endorsing.pluck(:priority_id))
      elsif current_user.down_endorsements_count > 0
        @priorities = Priority.published.top_rank.page(params[:page]).per(params[:per_page])
          .where("priorities.id in (?) and priorities.down_documents_count = 0",
                  current_user.endorsements.active_and_inactive.opposing.pluck(:priority_id))
      end
      @endorsements = nil
      if logged_in? # pull all their endorsements on the priorities shown
        @endorsements = current_user.endorsements.active.where(priority_id: @priorities.pluck(:id))
      end
    else
      @priorities = nil
    end
    respond_to do |format|
      format.html
      format.xml { render xml: @priorities }
      format.json { render json: @priorities }
    end
  end
  
  def contributors
    @page_title = t('briefing.contributors.title')
    @contributors = User.active.contributors.order("users.contribution_points desc")
      .page(params[:page]).per(params[:per_page])
    respond_to do |format|
      format.html
      format.xml { render xml: @contributors }
      format.json { render json: @contributors }
    end
  end

end
