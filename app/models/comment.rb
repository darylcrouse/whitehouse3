class Comment < ApplicationRecord
  belongs_to :activity, counter_cache: :comments_count
  belongs_to :user

  validates :content, presence: true

  before_create :set_side
  after_create  :bump_user_count
  after_destroy :drop_user_count

  scope :published, -> { where(status: "published") }
  scope :newest,    -> { order(created_at: :desc) }

  private

  # Record whether the commenter endorses/opposes the activity's priority, so the
  # view can label "endorser" / "opposer" like the original did.
  def set_side
    priority = activity&.priority
    return unless priority
    self.is_endorser = user.endorsed?(priority)
    self.is_opposer  = user.opposed?(priority)
  end

  def bump_user_count
    User.where(id: user_id).update_all("comments_count = comments_count + 1")
  end

  def drop_user_count
    User.where(id: user_id).update_all("comments_count = comments_count - 1")
  end
end
