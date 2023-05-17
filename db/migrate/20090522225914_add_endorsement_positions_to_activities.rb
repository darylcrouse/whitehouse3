class AddEndorsementPositionsToActivities < ActiveRecord::Migration[7.0]
  def self.up
    remove_column :activities, :endorsement_id
  end

  def self.down
  end
end
