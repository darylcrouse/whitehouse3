class AboutController < ApplicationController
  
  def index
    @page_title = t('about.index', :government_name => current_government.name)
  end
  
  def show
    if params[:id] == 'privacy'
      @page_title = t('about.privacy', :government_name => current_government.name)       
      render :action => "privacy"
    elsif params[:id] == 'rules'
      @page_title = t('about.rules', :government_name => current_government.name)     
      render :action => "rules"
    elsif params[:id] == 'faq'
      @page_title = t('about.faq', :government_name => current_government.name)      
      render :action => "faq"
    elsif params[:id] == 'stimulus'
      @page_title = "How America rates the stimulus package"
      render :action => "stimulus"      
    elsif params[:id] == 'congress'
      redirect_to "http://hellocongress.org/"
      return
    else
      @page = Page.find_by_short_name(params[:id])
      if @page
        @page_title = @page.name
      elsif params[:id] == 'press'
        redirect_to action: :faq
      else
        redirect_to action: :index
      end
    end
  end

  # The menu links target these as actions; /about/<name> is also serviced by
  # #show via the resources route above.
  def faq
    @page_title = t('about.faq', :government_name => current_government.name)
  end

  def privacy
    @page_title = t('about.privacy', :government_name => current_government.name)
  end

  def rules
    @page_title = t('about.rules', :government_name => current_government.name)
  end

  # No press page carries over from the original; send readers to the FAQ.
  def press
    redirect_to action: :faq
  end

end
