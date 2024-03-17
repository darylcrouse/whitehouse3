class AboutController < ApplicationController
  def index
    @page_title = t('about.index', government_name: current_government.name)
  end

  def show
    case params[:id]
    when 'privacy'
      @page_title = t('about.privacy', government_name: current_government.name)
      render action: "privacy"
    when 'rules'
      @page_title = t('about.rules', government_name: current_government.name)
      render action: "rules"
    when 'faq'
      @page_title = t('about.faq', government_name: current_government.name)
      render action: "faq"
    when 'stimulus'
      @page_title = "How America rates the stimulus package"
      render action: "stimulus"
    when 'congress'
      redirect_to "http://hellocongress.org/"
    else
      @page = Page.find_by(short_name: params[:id])
      @page_title = @page.name
      render action: "show"
    end
  end
end
