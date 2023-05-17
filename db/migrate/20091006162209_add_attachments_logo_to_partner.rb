class AddAttachmentsLogoToPartner < ActiveRecord::Migration[7.0]

  def change
    remove_column :partners, :logo_file_name
    remove_column :partners, :logo_content_type
    remove_column :partners, :logo_file_size
    remove_column :partners, :logo_updated_at
  end
end
