class ColorScheme < ActiveRecord::Base

  scope :featured, -> { where(is_featured: true) }

  after_save :clear_cache
  
  has_one_attached :background
  validate :background_image_type, :background_image_size
  
  def clear_cache
    Rails.cache.delete('views/color_scheme/'+id.to_s)
    return true
  end
  
  def ColorScheme.not_colors
    ['id','updated_at','fonts','background_tiled','created_at','is_featured','background_image_file_name', 'background_image_content_type', 'background_image_file_size', 'background_image_updated_at']
  end
  
  def ColorScheme.theme_colors
    ['background', 'link', 'main', 'text', 'box', 'box_text', 'comments', 'comments_text', 'footer', 'footer_text', 'heading', 'sub_heading', 'nav_background', 'nav_text', 'nav_selected_background', 'nav_selected_text', 'nav_hover_background', 'nav_hover_text', 'action_button', 'action_button_border']
  end

  def unique_colors
    colors = []
    for column in ColorScheme.column_names
      colors << self[column].upcase if ColorScheme.theme_colors.include?(column) and not ['000000','FFFFFF'].include?(self[column].upcase)
    end
    colors.uniq
  end
  
  private

  def background_image_type
    if background.attached? && !background.content_type.in?(%w(image/jpeg image/png image/gif))
      errors.add(:background, 'must be a JPEG PNG or GIF')
    end
  end

  def background_image_size
    if background.attached? && background.blob.byte_size > 5.megabytes
      errors.add(:background, 'size must be less than 10MB')
    end
  end
end
