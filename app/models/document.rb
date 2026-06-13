# A collaborative long-form document attached to a Priority (supporting, opposing
# or neutral). A lightweight wiki-style essay.
class Document < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :priority

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
  scope :newest, -> { order(created_at: :desc) }

  def supporting? = value.to_i.positive?
  def opposing?   = value.to_i.negative?

  def side_name
    return "supports" if supporting?
    return "opposes" if opposing?
    "is neutral on"
  end

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def increment_counts
    Priority.where(id: priority_id).update_all("documents_count = documents_count + 1")
  end

  def decrement_counts
    Priority.where(id: priority_id).update_all("documents_count = documents_count - 1")
  end

  def create_activity
    ActivityDocumentNew.create(user: user, priority: priority, document: self) if user
  end
end
