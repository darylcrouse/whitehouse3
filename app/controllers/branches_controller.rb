class BranchesController < ApplicationController

  before_action :admin_required

  # GET /branches
  def index
    @page_title = t('branches.index.title', government_name: current_government.name)
    @branches = Branch.all
    respond_to do |format|
      format.html 
      format.xml  { render xml: @branches }
    end
  end

  # GET /branches/new
  def new
    @page_title = t('branches.new.title')
    @branches = Branch.all    
    @branch = Branch.new
    respond_to do |format|
      format.html { render action: "edit" }
      format.xml  { render xml: @branch }
    end
  end

  # GET /branches/1/edit
  def edit
    @branches = Branch.all  
    @branch = Branch.find(params[:id])
    @page_title = t('branches.edit.title', branch_name: @branch.name)        
  end

  # POST /branches
  def create
    @page_title = t('branches.new.title')    
    @branches = Branch.all    
    @branch = Branch.new(branch_params)
    respond_to do |format|
      if @branch.save
        flash[:notice] = t('branches.new.success', branch_name: @branch.name)
        format.html { redirect_to(edit_branch_url(@branch)) }
        format.xml  { render xml: @branch, status: :created, location: @branch }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @branch.errors, status: :unprocessable_entity } 
      end
    end
  end

  # PUT /branches/1
  def update
    @branches = Branch.all
    @branch = Branch.find(params[:id])
    @page_title = t('branches.edit.title', branch_name: @branch.name)        
    respond_to do |format|
      if @branch.update(branch_params)
        flash[:notice] = t('branches.new.success', branch_name: @branch.name)
        format.html { redirect_to(edit_branch_url(@branch)) }
        format.xml  { head :ok }
      else
        format.html { render action: "edit" }
        format.xml  { render xml: @branch.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /branches/1
  def destroy
    @branch
