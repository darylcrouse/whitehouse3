# A user's rating of a Point as helpful (value true) or unhelpful (false).
class PointQuality < ApplicationRecord
  belongs_to :user
  belongs_to :point

  validates :user_id, uniqueness: { scope: :point_id }

  after_save    :refresh_point
  after_destroy :refresh_point

  private

  def refresh_point
    helpful   = PointQuality.where(point_id: point_id, value: true).count
    unhelpful = PointQuality.where(point_id: point_id, value: false).count
    Point.where(id: point_id).update_all(helpful_count: helpful, unhelpful_count: unhelpful)
  end
end
