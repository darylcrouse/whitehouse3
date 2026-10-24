# Extracted from app/models/notification.rb so Zeitwerk can reload this
# constant on its own. See the note at the bottom of notification.rb.

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
