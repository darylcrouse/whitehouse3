class PagesController < ApplicationController
  def show
    @page = Page.find_by!(short_name: params[:short_name])
  end
end
