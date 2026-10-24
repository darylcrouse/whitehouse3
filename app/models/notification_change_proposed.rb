# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationChangeProposed < Notification
  
  def name
    I18n.t('notification.change.proposed.name', :sender_name => sender.name, :priority_name => notifiable.priority_name, :new_priority_name => notifiable.new_priority.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end
  
end
