require 'digest/sha1'
class ImportController < ApplicationController

  before_action :login_required
  protect_from_forgery :except => :windows
  
  def google
    # Google Contacts shut its API down and the legacy `contacts` gem is
    # retired; this import flow cannot authenticate anymore.
    import_unavailable
  end
  
  def yahoo
    import_unavailable
  end  

  def windows
    if not request.post?
      import_unavailable
      return
    end
    @user = User.find(current_user.id)
    @user.is_importing_contacts = true
    @user.imported_contacts_count = 0
    @user.save_with_validation(false)
    Delayed::Job.enqueue LoadWindowsContacts.new(@user.id,request.raw_post), 5
    redirect_to :action => "status"    
  end

  private

  def import_unavailable
    flash[:error] = t('import.unavailable', default: 'Importing contacts from this provider is no longer available.')
    redirect_to action: 'status'
  end

  def status
    @page_title = t('import.started')
    respond_to do |format|
      if not current_user.is_importing_contacts?
        flash[:notice] = t('import.finished')
        if current_user.contacts_members_count > 0
          format.html { redirect_to members_user_contacts_path(current_user) }
          format.js { redirect_from_facebox(members_user_contacts_path(current_user)) }
        else
          format.html { redirect_to not_invited_user_contacts_path(current_user) }
          format.js { redirect_from_facebox(not_invited_user_contacts_path(current_user)) }          
        end
      else
        format.html
        format.js {
          render :update do |page|        
            page[:number_completed].replace_html current_user.imported_contacts_count
          end
        }
      end
    end
  end
  
end
