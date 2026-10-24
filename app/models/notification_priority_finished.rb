# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

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
