# A factual argument attached to a Priority, supporting it (value 1), opposing it
# (value -1) or neutral (0). Other users rate points helpful/unhelpful.
class Point < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :priority
  belongs_to :other_priority, class_name: "Priority", optional: true

  has_many :point_qualities, dependent: :destroy
  has_many :activities, dependent: :nullify

  validates :name, presence: true, length: { maximum: 140 }
  validates :content, presence: true

  before_validation :set_published_at, on: :create
  after_create  :increment_counts
  after_create  :create_activity
  after_destroy :decrement_counts

  scope :published, -> { where(status: "published") }
  scope :supporting, -> { where("value > 0") }
  scope :opposing,   -> { where("value < 0") }
  scope :neutral,    -> { where(value: 0) }
  scope :by_helpfulness, -> { order(Arel.sql("(helpful_count - unhelpful_count) DESC")) }
  scope :newest, -> { order(created_at: :desc) }

  def supporting?
    value.to_i.positive?
  end

  def opposing?
    value.to_i.negative?
  end

  def neutral?
    value.to_i.zero?
  end

  def side_name
    return "supports" if supporting?
    return "opposes" if opposing?
    "is neutral on"
  end

  def helpfulness
    helpful_count - unhelpful_count
  end

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def increment_counts
    col = supporting? ? "up_points_count" : (opposing? ? "down_points_count" : "neutral_points_count")
    Priority.where(id: priority_id).update_all("points_count = points_count + 1, #{col} = #{col} + 1")
    User.where(id: user_id).update_all("points_count = points_count + 1") if user_id
  end

  def decrement_counts
    col = supporting? ? "up_points_count" : (opposing? ? "down_points_count" : "neutral_points_count")
    Priority.where(id: priority_id).update_all("points_count = points_count - 1, #{col} = #{col} - 1")
    User.where(id: user_id).update_all("points_count = points_count - 1") if user_id
  end

  def create_activity
    ActivityPointNew.create(user: user, priority: priority, point: self) if user
  end
end
