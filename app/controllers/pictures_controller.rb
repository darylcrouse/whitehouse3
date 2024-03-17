class PicturesController < ApplicationController
  layout false

  before_action :get_picture

  require 'rmagick'

  def get
    response.headers['Cache-Control'] = 'public'
    send_data @picture.data, type: @picture.content_type, disposition: 'inline'
  end

  def get_thumbnail
    response.headers['Cache-Control'] = 'public'
    send_data @picture.thumbnail_data, type: @picture.content_type, disposition: 'inline'
  end

  def show_in_gallery
    response.headers['Cache-Control'] = 'public'
    render layout: "gallery"
  end

  def show_wide
    @picture = Picture.find(params[:id])  
    response.headers['Cache-Control'] = 'public'
    render layout: "gallery_wide"
  end

  private
    def get_picture
      @picture = Picture.find(params[:id])
    end
end
