class EndorsementsController < ApplicationController
 
  before_filter :login_required, :except => :index
  
  # GET /endorsements
  # GET /endorsements.xml
  def index
    @endorsements = Endorsement.active.by_position.find(:all, :include => :user, :limit => 5)
    respond_to do |format|
      format.html # index.html.erb
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /priorities/1/endorsements
  # GET /priorities/1/endorsements.xml
  def show
    @priority = Priority.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end    
  end

  # GET /priorities/1/endorsements/new
  def new
    @priority = Priority.find(params[:priority_id])
    @endorsement = @priority.endorsements.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # POST /priorities/1/endorsements
  # POST /priorities/1/endorsements.xml
  def create
    @priority = Priority.find(params[:priority_id])    
    @endorsement = @priority.endorse(current_user,request,current_partner,params[:referral_id])
    respond_to do |format|
      if @endorsement.save
        format.html { redirect_to(@priority, :notice => 'Successfully endorsed.') }
        format.js {
          render :update do |page|
            page.replace 'endorsement_' + @priority.id.to_s, render(:partial => "endorsements/update", :locals => {:priority => @priority, :endorsement => @endorsement})
            page.replace 'endorsement_count_' + @priority.id.to_s, render(:partial => "endorsements/endorsement_count", :locals => {:priority => @priority})            
            page.replace 'endorse_or_oppose_' + @priority.id.to_s, render(:partial => "endorsements/endorse_or_oppose", :locals => {:priority => @priority})                      
            page << "jQuery('#priority_#{@priority.id.to_s}_endorsed_button').button('option', 'disabled', true);"
          end
        }        
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /endorsements/1
  # PUT /endorsements/1.xml
  def update
    @endorsement = current_user.endorsements.find(params[:id])
    respond_to do |format|
      if @endorsement.update_attributes(params[:endorsement])
        format.html { redirect_to(@endorsement, :notice => 'Endorsement was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /endorsements/1
  # DELETE /endorsements/1.xml
  def destroy
    @endorsement = current_user.endorsements.find(params[:id])
    return unless @endorsement.destroy
    
    redirect_back_or_default '/'
    
  end

end
