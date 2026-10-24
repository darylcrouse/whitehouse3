# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationCommentFlagged < Notification
  
  def name
    I18n.t('notification.comment.flagged.name', :sender_name => sender.name, :user_name => notifiable.user.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_admin_subscribed?
  end  
  
end
