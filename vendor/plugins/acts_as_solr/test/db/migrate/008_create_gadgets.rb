class CreateGadgets < ActiveRecord::Migration[7.0]
  def self.up
    create_table :gadgets, :force => true do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :gadgets
  end
end
