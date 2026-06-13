# A proposed change to a priority (e.g. rename or merge). The community votes to
# approve or decline it.
class Change < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :priority
  belongs_to :new_priority, class_name: "Priority", optional: true

  has_many :votes, dependent: :destroy

  validates :content, presence: true

  scope :sent,     -> { where(status: "sent") }
  scope :approved, -> { where(status: "approved") }
  scope :declined, -> { where(status: "declined") }
  scope :newest,   -> { order(created_at: :desc) }

  def vote(user, value)
    v = votes.find_or_initialize_by(user_id: user.id)
    v.value = value
    v.voted_at = Time.current
    v.save
    refresh_tallies
    v
  end

  def refresh_tallies
    update_columns(
      yes_votes:   votes.where("value > 0").count,
      no_votes:    votes.where("value < 0").count,
      votes_count: votes.count
    )
  end

  def approve!
    update(status: "approved", approved_at: Time.current)
  end

  def decline!
    update(status: "declined", declined_at: Time.current)
  end

  def open?
    status == "sent"
  end
end
