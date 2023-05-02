class RemoveaasmState < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :aasm_state
  end
end
