class ChangeActivitiesTable < ActiveRecord::Migration[7.0]
  def self.up
    add_column :activities, :ignorers_count, :integer, :default => 0
    remove_column :activities, :letter_id
    remove_column :activities, :picture_id

    remove_column :activities, :user_chart_id
  end

  def self.down
  end
end
