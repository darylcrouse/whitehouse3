class DelayedJob < ActiveRecord::Base

  scope :by_priority, -> { reorder(locked_by: :asc, priority: :desc, run_at: :asc) }
  
end
