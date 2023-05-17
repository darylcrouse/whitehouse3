class AddTextToButtonsColorScheme < ActiveRecord::Migration[7.0]
  def self.up
    for c in ColorScheme.all
      c.update_attribute(:action_button_text, c.text) 
      c.update_attribute(:grey_button_text, c.text)       
    end
  end

  def self.down
  end
end
