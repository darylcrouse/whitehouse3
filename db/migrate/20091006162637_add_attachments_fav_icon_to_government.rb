class AddAttachmentsFavIconToGovernment < ActiveRecord::Migration[7.0]
  def change
    remove_column :governments, :fav_icon_file_name
    remove_column :governments, :fav_icon_content_type
    remove_column :governments, :fav_icon_file_size
    remove_column :governments, :fav_icon_updated_at
  end
end
