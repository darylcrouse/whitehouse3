class Tag < ActiveRecord::Base

  extend ActiveSupport::Concern

  scope :by_endorsers_count, -> { order(up_endorsers_count: :desc) }
  scope :alphabetical, -> { order(name: :asc) }
  scope :more_than_three_priorities, -> { where('priorities_count > ?', 3) }
  scope :with_priorities, -> { where('priorities_count > ?', 0) }
  scope :most_priorities, -> { with_priorities.order(priorities_count: :desc) }
  scope :most_webpages, -> { where('webpages_count > ?', 0).order(webpages_count: :desc) }
  scope :most_feeds, -> { where('feeds_count > ?', 0).order(feeds_count: :desc) }
  
  has_many :activities, :dependent => :destroy
  has_many :taggings
  has_many :priorities, -> { where taggings: { taggable_type: 'Priority' } }, through: :taggings, source: :priority
  has_many :webpages, -> { where taggings: { taggable_type: 'Webpage' } }, through: :taggings, source: :webpage
  has_many :feeds, -> { where taggings: { taggable_type: 'Feed' } }, through: :taggings, source: :feed
                            
  belongs_to :top_priority, :class_name => "Priority", :foreign_key => "top_priority_id"
  belongs_to :rising_priority, :class_name => "Priority", :foreign_key => "rising_priority_id"
  belongs_to :controversial_priority, :class_name => "Priority", :foreign_key => "controversial_priority_id"  
  belongs_to :obama_priority, :class_name => "Priority", :foreign_key => "obama_priority_id"    
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :within => 1..60
  validates_length_of :title, :within => 1..60, :allow_blank => true, :allow_nil => true
  
  cattr_reader :per_page
  @@per_page = 15  
  
  before_save :update_slug
  
  after_create :expire_cache
  after_destroy :expire_cache
  
  def expire_cache
    Tag.expire_cache
  end
  
  def Tag.expire_cache
    Rails.cache.delete('Tag.by_endorsers_count.all')
  end
  
  def update_slug
    self.slug = self.to_url
    self.title = self.name.titleize unless self.attribute_present?("title")
  end  
  
  def to_url
    "#{name.gsub(/[^a-z0-9]+/i, '-').downcase[0..60]}"
  end

  def to_s
    name
  end
  
  # LIKE is used for cross-database case-insensitivity
  def self.find_or_create_with_like_by_name(name)
    find(:first, :conditions => ["name LIKE ?", name]) || create(:name => name)
  end
  
  def ==(object)
    super || (object.is_a?(Tag) && name == object.name)
  end
  
  def endorsements_count
    up_endorsers_count+down_endorsers_count
  end
  
  def count
    read_attribute(:count).to_i
  end
  
  def prompt_display
    return prompt if attribute_present?("prompt")
    return Government.current.prompt
  end
  
  def published_priority_ids
    @published_priority_ids ||= Priority.published.tagged_with(self.name, on: :issues).pluck(:id)
  end

  
  def calculate_discussions_count
    Activity.active.discussions.for_all_users.by_recently_updated.count(:conditions => ["priority_id in (?)",published_priority_ids])
  end
  
  def calculate_points_count
    Point.published.count(:conditions => ["priority_id in (?)",published_priority_ids])
  end  
  
  def calculate_documents_count
    Document.published.count(:conditions => ["priority_id in (?)",published_priority_ids])
  end
  
  def update_counts
    self.priorities_count = priorities.published.count
    self.documents_count = calculate_documents_count
    self.points_count = calculate_points_count
    self.discussions_count = calculate_discussions_count
  end  
  
  def has_top_priority?
    attribute_present?("top_priority_id")
  end
  
  def rising_7days_count
    priorities.published.rising_7days.count
  end
  
  def flat_7days_count
    priorities.published.flat_7days.count
  end
  
  def falling_7days_count
    priorities.published.falling_7days.count
  end    
  
  def rising_7days_percent
    priorities.published.rising_7days.count.to_f/priorities_count.to_f
  end  
  
  def flat_7days_percent
    priorities.published.flat_7days.count.to_f/priorities_count.to_f
  end
  
  def falling_7days_percent
    priorities.published.falling_7days.count.to_f/priorities_count.to_f
  end    
  
  def rising_30days_count
    priorities.published.rising_30days.count
  end
  
  def flat_30days_count
    priorities.published.flat_30days.count
  end
  
  def falling_30days_count
    priorities.published.falling_30days.count
  end    
  
  def rising_24hr_count
    priorities.published.rising_24hr.count
  end
  
  def flat_24hr_count
    priorities.published.flat_24hr.count
  end
  
  def falling_24hr_count
    priorities.published.falling_24hr.count
  end  
  
  def subscribers
    User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.priority_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Priority'
    and endorsements.status = 'active'
    and endorsements.user_id = users.id
    and users.is_newsletter_subscribed = true
    and users.status in ('active','pending')",id])
  end
  
  def endorsers
    User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.priority_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Priority'
    and endorsements.status = 'active'
    and endorsements.value = 1
    and endorsements.user_id = users.id
    and users.status in ('active','pending')",id])
  end
  
  def opposers
    User.find_by_sql(["
    select distinct users.*
    from users, endorsements, taggings
    where 
    endorsements.priority_id = taggings.taggable_id
    and taggings.tag_id = ?
    and taggings.taggable_type = 'Priority'
    and endorsements.status = 'active'
    and endorsements.value = -1
    and endorsements.user_id = users.id
    and users.status in ('active','pending')",id])
  end
end
