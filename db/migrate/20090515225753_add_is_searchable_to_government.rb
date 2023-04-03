class AddIsSearchableToGovernment < ActiveRecord::Migration[7.0]
  def self.up
    add_column :governments, :is_searchable, :boolean, :default => false
  end

  def self.down
  end
end
