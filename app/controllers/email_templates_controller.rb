class EmailTemplatesController < ApplicationController

  before_filter :admin_required

  # GET /email_templates
  # GET /email_templates.xml
  def index
    @templates = EmailTemplate.find(:all)    
    @page_title = t('email_templates.index.title', :government_name => current_government.name)

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @templates }
    end
  end

  # GET /email_templates/1
  # GET /email_templates/1.xml
  def show
    @email_template = EmailTemplate.find(params[:id])

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @email_template }
    end
  end

  # GET /email_templates/new
  # GET /email_templates/new.xml
  def new
    @email_template = EmailTemplate.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @email_template }
    end
  end

  # GET /email_templates/1/edit
  def edit
    @email_template = EmailTemplate.find(params[:id])
  end

  # POST /email_templates
  # POST /email_templates.xml
  def create
    @email_template = EmailTemplate.new(params[:email_template])

    respond_to do |format|
      if @email_template.save
        flash[:notice] = t('email_templates.new.success')
        format.html { redirect_to(@email_template) }
        format.xml  { render :xml => @email_template, :status => :created, :location => @email_template }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @email_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /email_templates/1
  # PUT /email_templates/1.xml
  def update
    @email_template = EmailTemplate.find(params[:id])

    respond_to do |format|
      if @email_template.update_attributes(params[:email_template])
        flash[:notice] = t('email_templates.edit.success')
        format.html { redirect_to(@email_template) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @email_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /email_templates/1
  # DELETE /email_templates/1.xml
  def destroy
    @email_template = EmailTemplate.find(params[:id])
    @email_template.destroy

    respond_to do |format|
      format.html { redirect_to(email_templates_url) }
      format.xml  { head :ok }
    end
  end
end
