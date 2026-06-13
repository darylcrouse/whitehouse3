class IssuesController < ApplicationController
  
  before_action :get_tag_names, except: :index
  before_action :check_for_user, only: [:yours, :yours_finished, :yours_created, :network]
      
  def index
    @page_title = current_government.tags_name.pluralize.titleize
    if request.format != 'html' or current_government.tags_page == 'list'
      @issues = Tag.most_priorities.paginate(page: params[:page], per_page: params[:per_page])
    end
    respond_to do |format|
      format.html {
        if current_government.tags_page == 'cloud'
          render template: "issues/cloud"
        elsif current_government.tags_page == 'list'
          render template: "issues/index"
        end
      }
      format.xml { render xml: @issues.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @issues.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  def show
    if not @tag
      flash[:error] = t('tags.show.gone', tags_name: current_government.tags_name.downcase)
      redirect_to "/" and return 
    end
    @page_title = t('tags.show.title', tag_name: @tag_names.titleize, target: current_government.target)
    @priorities = Priority.tagged_with(@tag_names, on: :issues).published.top_rank.paginate(page: params[:page], per_page: params[:per_page])
    get_endorsements    
    respond_to do |format|
      format.html { render action: "list" }
      format.js { render layout: false, content_type: 'text/javascript', body: "document.write('#{j(render(layout: false, template: 'priorities/list_widget_small'))}');" }            
      format.xml { render xml: @priorities.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @priorities.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end    
  end

  alias top show

  def yours
    @page_title = t('tags.yours.title', tag_name: @tag_names.titleize, target: current_government.target)
    @priorities = @user.priorities.tagged_with(@tag_names, on: :issues).paginate(page: params[:page], per_page: params[:per_page])
    get_endorsements if logged_in?
    respond_to do |format|
      format.html { render action: "list" }
      format.js { render layout: false, content_type: 'text/javascript', body: "document.write('#{j(render(layout: false, template: 'priorities/list_widget_small'))}');" }           
      format.xml { render xml: @priorities.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @priorities.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end   
  end

  def yours_finished
    @page_title = t('tags.yours_finished.title', tag_name: @tag_names.titleize)
    @priorities = @user.finished_priorities.finished.tagged_with(@tag_names, on: :issues, order: "priorities.status_changed_at desc").paginate(page: params[:page], per_page: params[:per_page])
    respond_to do |format|
      format.html { render action: "list" }
      format.js { render layout: false, content_type: 'text/javascript', body: "document.write('#{j(render(layout: false, template: 'priorities/list_widget_small'))}');" }      
      format.xml { render xml: @priorities.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @priorities.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def yours_created
    @page_title = t('tags.yours_created.title', tag_name: @tag_names.titleize)
    @priorities = @user.created_priorities.tagged_with(@tag_names, on: :issues).paginate(page: params[:page], per_page: params[:per_page])
    get_endorsements if logged_in?
    respond_to do |format|
      format.html { render action: "list" }
      format.js { render layout: false, content_type: 'text/javascript', body: "document.write('#{j(render(layout: false, template: 'priorities/list_widget_small'))}');" }      
      format.xml { render xml: @priorities.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @priorities.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end
  end  
  
  def network
    @page_title = t('tags.network.title', tag_name: @tag_names.titleize, target: current_government.target)
    @tag_priorities = Priority.published.tagged_with(@tag_names, on: :issues)
    if @user.followings_count > 0
      @priorities = Endorsement.active.select("endorsements.priority_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number, priorities.*")
        .joins("INNER JOIN priorities ON priorities.id = endorsements.priority_id")
        .where("endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position} and endorsements.priority_id in (?)", @user.followings.up.pluck(:other_user_id), @tag_priorities.pluck(:id))
        .group("endorsements.priority_id")
        .order("score desc").paginate(page: params[:page])
        
      if logged_in?  
        @endorsements = current_user.endorsements.active.where(priority_id: @priorities.map(&:id))
      end
    end
    respond_to do |format|
      format.html
      format.js { render layout: false, content_type: 'text/javascript', body: "document.write('#{j(render(layout: false, template: 'priorities/list_widget_small'))}');" }            
      format.xml { render xml: @priorities.to_xml(include: :priority, except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @priorities.to_json(include: :priority, except: NB_CONFIG['api_exclude_fields']) }
    end    
  end
  
  protected
  
    def get_tag_names
      @tag = Tag.find_by(slug: params[:slug])
      if not @tag
        flash[:error] = t('tags.show.gone', tags_name: current_government.tags_name.downcase)
        redirect_to "/" and return
      end
      @tag_names = @tag.name
    end
  
    def check_for_user
      if params[:user_id]
        @user = User.find(params[:user_id])
      elsif logged_in?
        @user = current_user
      else
        access_denied and return
      end
    end
    
end
