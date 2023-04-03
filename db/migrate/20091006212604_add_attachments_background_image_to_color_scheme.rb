class AddAttachmentsBackgroundImageToColorScheme < ActiveRecord::Migration[7.0]
  def change
    remove_column :color_schemes, :background_picture_id
    remove_column :color_schemes, :background_image_file_name
    remove_column :color_schemes, :background_image_content_type
    remove_column :color_schemes, :background_image_file_size
    remove_column :color_schemes, :background_image_updated_at
  end
end
