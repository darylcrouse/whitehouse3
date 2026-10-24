# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationProfileBulletin < Notification
  
  def name
    I18n.t('notification.profile.bulletin.name', :sender_name => sender.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_messages_subscribed?
  end  
  
end
