# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationContactJoined < Notification
  
  def name
    I18n.t('notification.contact.joined.name', :sender_name => sender.name)
    sender.login + " just joined"
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end
