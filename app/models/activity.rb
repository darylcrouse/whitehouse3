# Activities make up the site-wide feed. Each subclass (STI) represents a kind of
# event — a new priority, an endorsement, a point, etc. Comments hang off an
# activity, turning any event into a small discussion thread.
class Activity < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :other_user, class_name: "User", optional: true
  belongs_to :priority, optional: true
  belongs_to :point, optional: true
  belongs_to :document, optional: true

  has_many :comments, -> { where(status: "published").order(created_at: :asc) }, dependent: :destroy

  scope :active, -> { where(status: "active") }
  scope :newest, -> { order(created_at: :desc) }
  scope :feed,   -> { active.where(is_user_only: false).newest }

  # Subclasses override this to describe the event. Returns a plain string; the
  # actor's name and links are added by the view.
  def sentence
    "did something"
  end

  # Can users comment on this activity?
  def commentable?
    true
  end

  def icon
    "•"
  end

  def actor
    user
  end
end
