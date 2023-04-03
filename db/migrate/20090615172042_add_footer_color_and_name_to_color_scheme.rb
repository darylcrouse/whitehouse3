class AddFooterColorAndNameToColorScheme < ActiveRecord::Migration[7.0]
  def self.up
    for c in ColorScheme.all
      c.update_attribute(:footer, c.box)
      c.update_attribute(:footer_text, c.box_text)
    end
  end

  def self.down
  end
end
