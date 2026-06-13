# A small named snippet of editable copy used around the site.
class Blurb < ApplicationRecord
  validates :name, presence: true, uniqueness: true

  def self.content_for(name, default = "")
    find_by(name: name)&.content.presence || default
  end
end
