class DocumentsController < ApplicationController
  
  before_filter :login_required, :only => [:new, :create, :quality, :unquality, :index, :your_priorities, :destroy]
  before_filter :admin_required, :only => [:edit, :update]

  # GET /documents
  # GET /documents.xml
  def index
    @page_title = t('document.yours.title')
    @documents = Document.published.by_author(current_user).paginate(:page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @documents.to_xml }
    end
  end

  # GET /documents/1
  # GET /documents/1.xml
  def show
    @document = Document.find(params[:id])
    @point = Point.new
    @qualities = nil
    if logged_in? and @document.priority
      @qualities = @document.priority.points.published.by_quality_score.find(:all, :conditions => ["points.user_id = ?", current_user.id], :include => :priority, :limit => 3)
    end    
  end

  # GET /documents/new
  # GET /documents/new.xml
  def new
    @document = Document.new
    @page
