# A private message between two users.
class Message < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :content, presence: true

  scope :inbox,  ->(user) { where(recipient_id: user.id, deleted_at: nil).order(created_at: :desc) }
  scope :sent,   ->(user) { where(sender_id: user.id).order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update_column(:read_at, Time.current) unless read?
  end
end
