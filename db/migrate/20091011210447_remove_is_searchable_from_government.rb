class RemoveIsSearchableFromGovernment < ActiveRecord::Migration[7.0]
  def self.up
    remove_column :governments, :is_searchable
  end

  def self.down
  end
end
