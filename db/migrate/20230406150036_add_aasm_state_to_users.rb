class AddAasmStateToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :aasm_state, :string
  end
end
