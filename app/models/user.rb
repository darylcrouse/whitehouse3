class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  belongs_to :branch, optional: true

  has_many :priorities, dependent: :nullify
  has_many :endorsements, dependent: :destroy
  has_many :endorsed_priorities, through: :endorsements, source: :priority
  has_many :points, dependent: :nullify
  has_many :documents, dependent: :nullify
  has_many :comments, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :point_qualities, dependent: :destroy

  has_many :sent_messages, class_name: "Message", foreign_key: :sender_id, dependent: :nullify
  has_many :received_messages, class_name: "Message", foreign_key: :recipient_id, dependent: :nullify
  has_many :notifications, class_name: "Notification", foreign_key: :recipient_id, dependent: :destroy

  has_many :followings, dependent: :destroy
  has_many :followed_users, through: :followings, source: :other_user
  has_many :follower_relationships, class_name: "Following", foreign_key: :other_user_id, dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :user

  belongs_to :top_endorsement, class_name: "Endorsement", optional: true

  validates :login, presence: true, uniqueness: { case_sensitive: false },
                     length: { within: 3..40 },
                     format: { with: /\A[a-z0-9_]+\z/i, message: "may only contain letters, numbers and underscores" }
  validates :email_address, presence: true

  scope :active,          -> { where(status: "active") }
  scope :by_score,        -> { order(score: :desc) }
  scope :most_active,     -> { order(endorsements_count: :desc) }
  scope :newest,          -> { order(created_at: :desc) }

  def name
    full = [first_name, last_name].compact_blank.join(" ")
    full.presence || login
  end

  def to_param
    login
  end

  def admin?
    is_admin?
  end

  def official?
    id == Government.current.official_user_id
  end

  # Has the user taken a position (up or down) on this priority?
  def endorsement_on(priority)
    endorsements.find_by(priority_id: priority.id)
  end

  def endorsed?(priority)
    e = endorsement_on(priority)
    e&.active? && e.up?
  end

  def opposed?(priority)
    e = endorsement_on(priority)
    e&.active? && e.down?
  end

  def following?(other)
    followings.where(other_user_id: other.id, value: 1).exists?
  end

  def gravatar_url(size = 48)
    hash = Digest::MD5.hexdigest(email_address.to_s.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=identicon"
  end
end
