class BranchEndorsement < ActiveRecord::Base

  belongs_to :branch
  belongs_to :priority
  has_many :charts, :class_name => "BranchEndorsementChart", :dependent => :destroy
  has_many :rankings, :class_name => "BranchEndorsementRanking", :dependent => :destroy
  
  scope :published, -> {
    if Government.current&.is_suppress_empty_priorities?
      where("priorities.status = 'published' and priorities.position > 0 and priorities.endorsements_count > 0")
    else
      where("priorities.status = 'published'")
    end
  }
  scope :finished, -> { where(priorities: { obama_status: [-2,-1,2] }) }
  
  scope :top_rank, -> { order("branch_endorsements.position asc") }
  scope :not_top_rank, -> { where("branch_endorsements.position > 25") }
  scope :rising, -> { where("branch_endorsements.position_7days_change > 0").order("(branch_endorsements.position_7days_change/branch_endorsements.position) desc") }
  scope :falling, -> { where("branch_endorsements.position_7days_change < 0").order("(branch_endorsements.position_7days_change/branch_endorsements.position) asc") }
  
  scope :rising_7days, -> { where("branch_endorsements.position_7days_change > 0") }
  scope :flat_7days, -> { where("branch_endorsements.position_7days_change = 0") }
  scope :falling_7days, -> { where("branch_endorsements.position_7days_change < 0") }
  scope :rising_30days, -> { where("branch_endorsements.position_30days_change > 0") }
  scope :flat_30days, -> { where("branch_endorsements.position_30days_change = 0") }
  scope :falling_30days, -> { where("branch_endorsements.position_30days_change < 0") }
  scope :rising_24hr, -> { where("branch_endorsements.position_24hr_change > 0") }
  scope :flat_24hr, -> { where("branch_endorsements.position_24hr_change = 0") }
  scope :falling_24hr, -> { where("branch_endorsements.position_24hr_change < 0") }
  
  scope :newest, -> { order("branch_endorsements.created_at desc") }
  scope :controversial, -> { where("branch_endorsements.down_endorsements_count > 0 and (branch_endorsements.up_endorsements_count/branch_endorsements.down_endorsements_count) between 0.5 and 2").order("(branch_endorsements.endorsements_count - abs(branch_endorsements.up_endorsements_count-branch_endorsements.down_endorsements_count)) desc") }
  
  
  acts_as_list -> { where(branch_id: branch_id) }
  
  # self.per_page = 25
  
  after_create :add_counts
  after_destroy :remove_counts
  
  def add_counts
    self.branch.increment!(:endorsements_count)
  end
  
  def remove_counts
    self.branch.decrement!(:endorsements_count)
  end
  
  def is_new?
    created_at > Time.now-(86400*7) or position_7days == 0    
  end
  
  def update_counts
    self.up_endorsements_count = Endorsement.count(:conditions => ["priority_id = ? and user_id in (?) and value = 1",self.priority_id, branch.user_ids])
    self.down_endorsements_count = Endorsement.count(:conditions => ["priority_id = ? and user_id in (?) and value = -1",self.priority_id, branch.user_ids])
    self.endorsements_count = self.up_endorsements_count+self.down_endorsements_count
  end
  
  def is_much_more_important?
    return false if position == 0
    return false unless is_more_important?
    return true if (position_difference/position) >= 0.1
  end
  
  def is_slightly_more_important?
    return false if position == 0
    return false unless is_more_important?    
    return true if (position_difference/position) < 0.1
  end  
  
  def is_more_important?
    return false if position == 0
    position < priority.position
  end
  
  def position_difference
    return 0 if position == 0 or priority.position == 0
    (position-priority.position).abs
  end
  
  def is_less_important?
    return false if position == 0
    position > priority.position
  end

  def is_slightly_less_important?
    return false if position == 0  
    return false unless is_less_important? 
    return true if (position_difference/priority.position) < 0.1
  end
  
  def is_much_less_important?
    return false if position == 0
    return false unless is_less_important?
    return true if (position_difference/priority.position) >= 0.1
  end

end
