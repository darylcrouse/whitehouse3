class Tagging < ApplicationRecord
  belongs_to :tag, counter_cache: false
  belongs_to :taggable, polymorphic: true
  belongs_to :tagger, class_name: "User", optional: true

  after_create  { tag&.refresh_counts! }
  after_destroy { tag&.refresh_counts! }
end
