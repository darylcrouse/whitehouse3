# An issue / category that groups priorities (and points, documents).
class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :priorities, through: :taggings, source: :taggable, source_type: "Priority"

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :set_slug

  scope :popular, -> { order(priorities_count: :desc) }
  scope :alphabetical, -> { order(name: :asc) }

  def to_param
    slug
  end

  def display_title
    title.presence || name
  end

  # Refresh denormalized priority count from current taggings.
  def refresh_counts!
    update_columns(priorities_count: taggings.where(taggable_type: "Priority").count)
  end

  private

  def set_slug
    self.slug ||= name.to_s.parameterize
  end
end
