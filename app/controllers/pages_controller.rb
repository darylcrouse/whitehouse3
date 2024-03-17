class PagesController < ApplicationController
  def show
    @page = Page.friendly.find(params[:id])
    @page_title = @page.title
    respond_to do |format|
      format.html
      format.xml { render xml: @page.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @page.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def usage
    @page_title = t('pages.usage.title', government_name: current_government.name)
  end

  def home
    @page_title = t('pages.home.title', government_name: current_government.name)
    respond_to do |format|
      format.html
      format.xml { render xml: @page.to_xml(except: NB_CONFIG['api_exclude_fields']) }
      format.json { render json: @page.to_json(except: NB_CONFIG['api_exclude_fields']) }
    end
  end

  def iframe
    render layout: false
  end
end
