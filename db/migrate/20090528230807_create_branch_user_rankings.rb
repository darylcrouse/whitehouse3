class CreateBranchUserRankings < ActiveRecord::Migration[7.0]
  def change
    drop_table :branch_user_rankings
    create_table :branch_user_rankings do |t|
      t.integer  "branch_id"      
      t.integer  "user_id"
      t.integer  "version",        :default => 0
      t.integer  "position"
      t.integer  "capitals_count", :default => 0
      t.datetime "created_at"
    end
    add_index :branch_user_rankings, :created_at
    add_index :branch_user_rankings, [:user_id, :branch_id], :name => "branch_uranks_id"
    add_index :branch_user_rankings, :version    
  end
end
