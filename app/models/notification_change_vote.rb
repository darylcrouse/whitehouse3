# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationChangeVote < Notification
  
  def name
    I18n.t('notification.change.vote.name', :priority_name => notifiable.change.priority_name, :new_priority_name => notifiable.change.new_priority.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_votes_subscribed?
  end  
  
end
