# A directed relationship: user follows (value 1) or ignores (value -1) other_user.
class Following < ApplicationRecord
  belongs_to :user
  belongs_to :other_user, class_name: "User"

  validates :user_id, uniqueness: { scope: :other_user_id }
  validate  :not_self

  after_create  :bump_counts
  after_destroy :drop_counts

  scope :following, -> { where(value: 1) }
  scope :ignoring,  -> { where(value: -1) }

  private

  def not_self
    errors.add(:other_user_id, "can't follow yourself") if user_id == other_user_id
  end

  def bump_counts
    return unless value == 1
    User.where(id: user_id).update_all("followings_count = followings_count + 1")
    User.where(id: other_user_id).update_all("followers_count = followers_count + 1")
  end

  def drop_counts
    return unless value == 1
    User.where(id: user_id).update_all("followings_count = followings_count - 1")
    User.where(id: other_user_id).update_all("followers_count = followers_count - 1")
  end
end
