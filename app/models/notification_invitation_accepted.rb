# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

class NotificationInvitationAccepted < Notification
  
  def name
    I18n.t('notification.invitation.accepted.name', :sender_name => sender.name, :government_name => Government.current.name)
  end
  
  def is_recipient_subscribed?
    recipient.is_followers_subscribed?
  end
  
end
