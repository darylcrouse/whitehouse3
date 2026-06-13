# A simple CMS page (About, Privacy, etc.) editable by admins.
class Page < ApplicationRecord
  validates :name, presence: true
  validates :short_name, presence: true, uniqueness: true

  before_validation :set_short_name

  def to_param
    short_name
  end

  private

  def set_short_name
    self.short_name ||= name.to_s.parameterize
  end
end
