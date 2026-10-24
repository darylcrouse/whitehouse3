class Notification < ActiveRecord::Base
  include AASM

  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :recipient, :class_name => "User", :foreign_key => "recipient_id"

  belongs_to :notifiable, :polymorphic => true

  scope :active, -> { where.not(status: 'deleted') }
  scope :unprocessed, -> { where(processed_at: nil) }
  scope :sent, -> { where(status: ['sent', 'read']) }
  scope :read, -> { where(status: 'read') }
  scope :unread, -> { where(status: ['sent', 'unsent']) }

  scope :messages, -> { where(type: 'NotificationMessage') }
  scope :comments, -> { where(type: 'NotificationComment') }

  scope :by_recently_created, -> { order(created_at: :desc) }
  scope :by_recently_sent, -> { order(sent_at: :desc) }
  scope :by_oldest_sent, -> { order(sent_at: :asc) }

  cattr_reader :per_page
  @@per_page = 30
  
  liquid_methods :name, :sender, :recipient, :sender_name, :recipient_name, :id

  aasm column: :status, whiny_transitions: true do
    state :unsent, after_enter: :queue_sending
    state :sent, after_enter: :do_send
    state :read, after_enter: :do_read  
    state :deleted, after_enter: :do_delete
    
    event :send do
      transitions from: :unsent, to: :sent
    end
    
    event :read do
      transitions from: [:sent, :unsent], to: :read
    end
  
    event :delete do
      transitions from: [:sent, :unsent, :read], to: :deleted
    end
  
    event :undelete do
      transitions from: :deleted, to: :read, guard: Proc.new { |p| !p.read_at.blank? }    
      transitions from: :deleted, to: :sent, guard: Proc.new { |p| !p.sent_at.blank? }
      transitions from: :deleted, to: :unsent 
    end
  end
  
  after_create :add_counts
  
  def add_counts
    recipient.increment!(:unread_notifications_count)
    recipient.increment!(:received_notifications_count)
  end
  
  # aasm 6 fires after_enter for the INITIAL state at after_initialize (i.e.
  # on .new), before the record is saved; queueing at .new would enqueue a job
  # for an unsaved notification. Fire on create instead.
  after_create :fire_initial_state_effects

  def fire_initial_state_effects
    queue_sending if aasm.current_state == :unsent
  end

  def queue_sending
    return if new_record?

    send_later(:send!)
  end
  
  def do_read
    self.deleted_at = nil
    self.read_at = Time.now
    recipient.decrement!(:unread_notifications_count)
  end
  
  def do_delete
    self.deleted_at = Time.now
    recipient.decrement!(:received_notifications_count)
    recipient.decrement!(:unread_notifications_count) if status != 'read'
  end
  
  def unread?
    ['sent','unsent'].include?(self.status)
  end
  
  def recipient_name
    recipient.name if recipient
  end
  
  def recipient_name=(n)
    self.recipient = User.find_by_login(n) unless n.blank?
  end
  
  def sender_name
    sender.name if sender
  end
  
  def sender_name=(n)
    self.sender = User.find_by_login(n) unless n.blank?
  end  
  
  def do_send
    self.deleted_at = nil    
    self.processed_at = Time.now
    if is_recipient_subscribed? and recipient.has_email? and recipient.is_active?
      self.sent_at = Time.now
      if self.class == NotificationChangeVote
        UserMailer.deliver_new_change_vote(sender,recipient,notifiable)
      else
        UserMailer.deliver_notification(self,sender,recipient,notifiable)
      end
    end
    #if recipient.has_facebook?
    #  self.sent_at = Time.now
    #  Facebooker::Session.create.send_notification([recipient.facebook_uid],fbml)
    #end    
  end  

  # you can override this in subclasses to specify a different rule for whether the person is subscribed
  def is_recipient_subscribed?
    recipient.is_newsletter_subscribed?
  end
  
end

# ---------------------------------------------------------------------------
# Subclasses live in their own files (app/models/notification_*.rb).
#
# This file used to define Notification and all sixteen STI subclasses
# together. Zeitwerk binds one autoload per file, so it could unload the base
# class but not the subclasses; after a dev reload the leftover constants kept
# the previous Notification as their superclass and re-running the file raised
#   TypeError: superclass mismatch for class NotificationChangeVote
# which surfaced as a 500 on any inbox page. One file per constant lets the
# loader unload and rebind each of them. Add new subclasses as their own file.
# ---------------------------------------------------------------------------
