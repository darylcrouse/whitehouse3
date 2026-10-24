# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationPointRevision < Notification
  
  def name
    I18n.t('notification.point.revision.name', :sender_name => sender.name, :point_name => notifiable.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_point_changes_subscribed?
  end  
  
end
