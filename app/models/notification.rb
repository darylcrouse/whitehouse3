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
    state :unsent, :enter => :queue_sending
    state :sent, :enter => :do_send
    state :read, :enter => :do_read  
    state :deleted, :enter => :do_delete
    
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
  
  def queue_sending
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

class NotificationChangeVote < Notification
  
  def name
    I18n.t('notification.change.vote.name', :priority_name => notifiable.change.priority_name, :new_priority_name => notifiable.change.new_priority.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_votes_subscribed?
  end  
  
end

class NotificationChangeProposed < Notification
  
  def name
    I18n.t('notification.change.proposed.name', :sender_name => sender.name, :priority_name => notifiable.priority_name, :new_priority_name => notifiable.new_priority.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end
  
end

class NotificationComment < Notification
  
  def name
    if notifiable.activity.has_document?
      I18n.t('notification.comment.name', :sender_name => sender.name, :comment_name => notifiable.activity.document.name)
    elsif notifiable.activity.has_point?
      I18n.t('notification.comment.name', :sender_name => sender.name, :comment_name => notifiable.activity.point.name)      
    elsif notifiable.activity.has_priority?
      I18n.t('notification.comment.name', :sender_name => sender.name, :comment_name => notifiable.activity.priority.name)      
    elsif notifiable.activity.class == ActivityBulletinProfileNew
      I18n.t('notification.comment.profile.name', :sender_name => sender.name, :user_name => notifiable.activity.user.name)
    else
      if notifiable.activity.user_id == recipient_id
        I18n.t('notification.comment.activity.yours.name', :sender_name => sender.name, :comment_name => notifiable.activity.name)              
      else
        I18n.t('notification.comment.activity.name', :sender_name => sender.name, :comment_name => notifiable.activity.name, :user_name => notifiable.activity.user.name)     
      end 
    end      
  end
  
  def is_recipient_subscribed?
    recipient.is_comments_subscribed?
  end  
  
end

class NotificationCommentFlagged < Notification
  
  def name
    I18n.t('notification.comment.flagged.name', :sender_name => sender.name, :user_name => notifiable.user.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationContactJoined < Notification
  
  def name
    I18n.t('notification.contact.joined.name', :sender_name => sender.name)
    sender.login + " just joined"
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationFollower < Notification
  
  def name
    I18n.t('notification.follower.name', :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_followers_subscribed?
  end  
  
end

class NotificationInvitationAccepted < Notification
  
  def name
    I18n.t('notification.invitation.accepted.name', :sender_name => sender.name, :government_name => Government.current.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_followers_subscribed?
  end
  
end

class NotificationMessage < Notification
  
  def name
    I18n.t('notification.message.name', :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_messages_subscribed?
  end  
  
end

class NotificationPriorityFlagged < Notification
  
  def name
    I18n.t('notification.priority.flagged.name', :sender_name => sender.name, :priority_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end

class NotificationProfileBulletin < Notification
  
  def name
    I18n.t('notification.profile.bulletin.name', :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_messages_subscribed?
  end  
  
end

class NotificationPointRevision < Notification
  
  def name
    I18n.t('notification.point.revision.name', :sender_name => sender.name, :point_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_point_changes_subscribed?
  end  
  
end

class NotificationDocumentRevision < Notification
  
  def name
    I18n.t('notification.document.revision.name', :sender_name => sender.name, :document_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_point_changes_subscribed?
  end  
  
end

class NotificationPriorityFinished < Notification
  
  def name
    if notifiable.priority.is_successful?
       I18n.t('activity.priority.obama_status.successful.name', :priority_name => notifiable.priority.name)
    elsif notifiable.priority.is_compromised?
      I18n.t('activity.priority.obama_status.compromised.name', :priority_name => notifiable.priority.name)
    elsif notifiable.priority.is_failed?
      I18n.t('activity.priority.obama_status.failed.name', :priority_name => notifiable.priority.name)
    elsif notifiable.priority.is_intheworks?
      I18n.t('activity.priority.obama_status.intheworks.name', :priority_name => notifiable.priority.name)
    end
  end
  
  def is_recipient_subscribed?
    recipient.is_finished_subscribed?
  end  
  
end

class NotificationWarning1 < Notification
  
  def name
    I18n.t('notification.warning1')
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end

class NotificationWarning2 < Notification
  
  def name
    I18n.t('notification.warning2')
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end

class NotificationWarning3 < Notification
  
  def name
    I18n.t('notification.warning3')
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end
