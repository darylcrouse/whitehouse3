# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationWarning3 < Notification
  
  def name
    I18n.t('notification.warning3')
  end
  
  def is_recipient_subscribed?
    true
  end  
  
end
