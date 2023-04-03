class AddAttachmentsLogoToGovernment < ActiveRecord::Migration[7.0]
  def change
    remove_column :governments, :logo_file_name
    remove_column :governments, :logo_content_type
    remove_column :governments, :logo_file_size
    remove_column :governments, :logo_updated_at
  end
end
