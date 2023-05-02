class Message < ActiveRecord::Base
  include AASM

  scope :active, -> { where.not(status: 'deleted') }
  scope :sent, -> { where(status: ['sent', 'read']) }
  scope :read, -> { where(status: 'read') }
  scope :unread, -> { where(status: 'sent') }
  scope :draft, -> { where(status: 'draft') }

  scope :by_recently_sent, -> { order(sent_at: :desc) }
  scope :by_oldest_sent, -> { order(sent_at: :asc) }
  scope :by_unread, -> { order(status: :desc, sent_at: :desc) }

  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"
  
  has_many :notifications, :as => :notifiable, :dependent => :destroy  
  
  validates_presence_of :content
  
  liquid_methods :content, :created_at
  
  aasm column: :status, whiny_transitions: true do
    state :draft, initial: true
    state :sent, enter: :do_send
    state :read, enter: :do_read
    state :deleted, enter: :do_delete

    event :send do
      transitions from: [:draft], to: :sent
    end

    event :read do
      transitions from: [:sent, :draft], to: :read
    end

    event :delete do
      transitions from: [:sent, :draft, :read], to: :deleted
    end

    event :undelete do
      transitions from: :deleted, to: :read, guard: :read_at_present?
      transitions from: :deleted, to: :sent, guard: :sent_at_present?
      transitions from: :deleted, to: :draft
    end
  end
  
  def do_send
    self.deleted_at = nil  
    if not Following.find_by_user_id_and_other_user_id_and_value(self.recipient_id,self.sender_id,-1) and self.sent_at.blank?
      self.notifications << NotificationMessage.new(:sender => self.sender, :recipient => self.recipient)
    end
    self.sent_at = Time.now
  end
  
  def do_read
    self.deleted_at = nil
    self.read_at = Time.now
    for n in self.notifications
      n.read!
      Rails.cache.delete("views/" + n[:type].downcase + "-" + n.id.to_s)
    end
  end
  
  def do_delete
    self.deleted_at = Time.now
    for n in self.notifications
      n.delete!
    end    
  end
  
  cattr_reader :per_page
  @@per_page = 25
  
  def unread?
    self.status == 'sent'
  end
  
  def recipient_name
    recipient.name if recipient
  end
  
  def recipient_name=(n)
    self.recipient = User.find_by_login(n) unless n.blank?
  end  
  
  auto_html_for(:content) do
    redcloth
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link(:rel => "nofollow")
  end  
  
end
