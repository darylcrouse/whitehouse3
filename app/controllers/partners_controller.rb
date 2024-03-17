class PartnersController < ApplicationController
  before_action :login_required

  def index
    @page_title = t('partners.index')
    @partners = Partner.by_name
    respond_to do |format|
      format.html
      format.xml { render xml: @partners.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @partners.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end
  end
end
