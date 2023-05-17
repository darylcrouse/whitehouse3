class AddScoreToEndorsements < ActiveRecord::Migration[7.0]
  def self.up
    remove_column :endorsements, :deleted_at
    # add_column :endorsements, :score, :integer, :default => 0
  end

  def self.down
  end
end
