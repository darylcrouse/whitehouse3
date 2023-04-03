class AddAttachmentsBuddyIconToUser < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :buddy_icon_file_name
    remove_column :users, :buddy_icon_content_type
    remove_column :users, :buddy_icon_file_size
    remove_column :users, :buddy_icon_updated_at
  end
end
