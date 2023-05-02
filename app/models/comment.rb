class Comment < ActiveRecord::Base
  include AASM

  scope :published, -> { where(status: 'published') }
  scope :published_and_abusive, -> { where(status: ['published', 'abusive']) }
  scope :deleted, -> { where(status: 'deleted') }
  scope :flagged, -> { where('flags_count > 0') }
    
  scope :last_three_days, -> { where('comments.created_at > ?', Time.now - 3.days) }
  scope :by_recently_created, -> { order(created_at: :desc) }  
  scope :by_first_created, -> { order(created_at: :asc) } 
    
  belongs_to :user
  belongs_to :activity
  
  has_many :notifications, :as => :notifiable, :dependent => :destroy
  
  validates_presence_of :content
  
  liquid_methods :id, :activity_id, :content, :user, :activity, :show_url
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  enum status: { published: 0, deleted: 1, abusive: 2 }

  aasm column: :status, enum: true, whiny_transitions: false do
    state :published, initial: true, before_enter: :do_publish
    state :deleted, before_enter: :do_delete
    state :abusive, before_enter: :do_abusive

    event :delete do
      transitions from: :published, to: :deleted
    end

    event :undelete do
      transitions from: :deleted, to: :published
    end

    event :abusive do
      transitions from: :published, to: :abusive
    end
  end
  
  def do_publish
    self.activity.changed_at = Time.now
    self.activity.comments_count += 1
    self.activity.save_with_validation(false)
    self.user.increment!("comments_count")
    for u in activity.followers
      if u.id != self.user_id and not Following.find_by_user_id_and_other_user_id_and_value(u.id,self.user_id,-1)
        notifications << NotificationComment.new(:sender => self.user, :recipient => u)
      end
    end
    if self.activity.comments_count == 1 # this is the first comment, so need to update the discussions_count as appropriate
      if self.activity.has_point? 
        Point.update_all("discussions_count = discussions_count + 1", "id=#{self.activity.point_id}")
      end
      if self.activity.has_document?
        Document.update_all("discussions_count = discussions_count + 1", "id=#{self.activity.document_id}")
      end
      if self.activity.has_priority?
        Priority.update_all("discussions_count = discussions_count + 1", "id=#{self.activity.priority_id}")
        if self.activity.priority.attribute_present?("cached_issue_list")
          for issue in self.activity.priority.issues
            issue.increment!(:discussions_count)
          end
        end        
      end
    end
    self.activity.followings.find_or_create_by_user_id(self.user_id)
    return if self.activity.user_id == self.user_id or (self.activity.class == ActivityBulletinProfileNew and self.activity.other_user_id = self.user_id and self.activity.comments_count < 2) # they are commenting on their own activity
    if exists = ActivityCommentParticipant.find_by_user_id_and_activity_id(self.user_id,self.activity_id)
      exists.increment!("comments_count")
    else
      ActivityCommentParticipant.create(:user => self.user, :activity => self.activity, :comments_count => 1, :is_user_only => true)
    end
  end
  
  def do_delete
    if self.activity.comments_count == 1
      self.activity.changed_at = self.activity.created_at
    else
      self.activity.changed_at = self.activity.comments.published.by_recently_created.first.created_at
    end
    self.activity.comments_count -= 1
    self.save_with_validation(false)    

    self.user.decrement!("comments_count")
    if self.activity.comments_count == 0
      if self.activity.has_point? and self.activity.point
        self.activity.point.decrement!(:discussions_count)
      end
      if self.activity.has_document? and self.activity.document
        self.activity.document.decrement!(:discussions_count)
      end
      if self.activity.has_priority? and self.activity.priority
        self.activity.priority.decrement!(:discussions_count)
        if self.activity.priority.attribute_present?("cached_issue_list")
          for issue in self.activity.priority.issues
            issue.decrement!(:discussions_count)
          end
        end
      end      
    end
    return if self.activity.user_id == self.user_id    
    exists = ActivityCommentParticipant.find_by_user_id_and_activity_id(self.user_id,self.id)
    if exists and exists.comments_count > 1
      exists.decrement!(:comments_count)
    elsif exists
      exists.delete!
    end
    for n in notifications
      n.delete!
    end
  end
  
  def do_abusive
    if self.user.warnings_count == 0 # this is their first warning, get a warning message
      notifications << NotificationWarning1.new(:recipient => self.user)
    elsif self.user.warnings_count == 1 # 2nd warning, lose 10% of pc
      notifications << NotificationWarning2.new(:recipient => self.user)
      capital_lost = (self.user.capitals_count*0.1).to_i
      capital_lost = 1 if capital_lost == 0
      ActivityCapitalWarning.create(:user => self.user, :capital => CapitalWarning.create(:recipient => self.user, :amount => -capital_lost))
    elsif self.user.warnings_count == 2 # third warning, on probation, lose 30% of pc
      notifications << NotificationWarning3.new(:recipient => self.user)      
      capital_lost = (self.user.capitals_count*0.3).to_i
      capital_lost = 3 if capital_lost < 3
      ActivityCapitalWarning.create(:user => self.user, :capital => CapitalWarning.create(:recipient => self.user, :amount => -capital_lost))
      self.user.probation!
    elsif self.user.warnings_count == 3 # fourth warning, suspended
      self.user.suspended!
    end
    self.update_attribute(:flags_count, 0)
    self.user.increment!("warnings_count")
  end
  
  def request=(request)
    self.ip_address = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end
  
  def parent_name 
    if activity.has_point?
      user.login + ' commented on ' + activity.point.name
    elsif activity.has_document?
      user.login + ' commented on ' + activity.document.name
    elsif activity.has_priority?
      user.login + ' commented on ' + activity.priority.name
    else
      user.login + ' posted a bulletin'
    end    
  end
  
  def flag_by_user(user)
    self.increment!(:flags_count)
    for r in User.active.admins
      notifications << NotificationCommentFlagged.new(:sender => user, :recipient => r)    
    end
  end
  
  def show_url
    Government.current.homepage_url + 'activities/' + activity_id.to_s + '/comments#' + id.to_s
  end
  
  auto_html_for(:content) do
    redcloth
    youtube(:width => 330, :height => 210)
    vimeo(:width => 330, :height => 180)
    link(:rel => "nofollow")
  end
  
end
