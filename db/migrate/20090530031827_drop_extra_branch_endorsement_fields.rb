class DropExtraBranchEndorsementFields < ActiveRecord::Migration[7.0]
  def self.up
    remove_column :branch_endorsement_charts, :up_count
    remove_column :branch_endorsement_charts, :down_count
    remove_column :branch_endorsement_charts, :volume_count
    remove_column :branch_user_charts, :up_count
    remove_column :branch_user_charts, :down_count
    remove_column :branch_user_charts, :volume_count    
  end

  def self.down
  end
end
