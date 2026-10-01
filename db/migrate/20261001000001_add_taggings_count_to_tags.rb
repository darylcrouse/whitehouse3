class AddTaggingsCountToTags < ActiveRecord::Migration[8.0]
  def change
    # acts-as-taggable-on keeps a counter cache on the tags table; the legacy
    # schema predates it.
    add_column :tags, :taggings_count, :integer, default: 0, null: false unless column_exists?(:tags, :taggings_count)
  end
end
