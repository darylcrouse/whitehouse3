class Notification < ApplicationRecord
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :recipient, class_name: "User"
  belongs_to :notifiable, polymorphic: true, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :newest, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_read!
    update_column(:read_at, Time.current) unless read?
  end
end
