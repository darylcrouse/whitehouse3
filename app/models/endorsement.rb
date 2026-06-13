# A user's position on a Priority: value +1 (endorse) or -1 (oppose), ranked by
# `position` within that user's personal list. The weighted `score` it contributes
# to the priority depends on the user's score and how high they ranked it.
class Endorsement < ApplicationRecord
  MAX_POSITION = Priority::MAX_POSITION

  belongs_to :user
  belongs_to :priority

  validates :user_id, uniqueness: { scope: :priority_id }

  before_validation :assign_bottom_position, on: :create
  before_save       :calculate_score
  after_create      :create_activity
  after_save        :sync_counts
  after_destroy     :sync_counts

  scope :active,   -> { where(status: "active") }
  scope :endorsing, -> { where("value > 0") }
  scope :opposing, -> { where("value < 0") }
  scope :by_position, -> { order(position: :asc) }

  def up?
    value.to_i.positive?
  end

  def down?
    !up?
  end

  def active?
    status == "active"
  end

  def value_name
    up? ? "endorsed" : "opposed"
  end

  # Move this endorsement to a new rank within the user's list, shifting others.
  def move_to(new_position)
    list = user.endorsements.active.by_position.to_a
    list.delete(self)
    list.insert([new_position - 1, 0].max, self)
    Endorsement.transaction do
      list.each_with_index do |e, i|
        e.update_columns(position: i + 1, score: e.send(:score_for_position, i + 1))
      end
    end
    list.map(&:priority).uniq.each(&:recalculate_score!)
    Priority.recalculate_positions!
  end

  private

  def score_for_position(pos)
    return 0 if pos > MAX_POSITION
    (user.score * value * (MAX_POSITION - pos)).to_i
  end

  def assign_bottom_position
    max = user.endorsements.where(status: "active").maximum(:position) || 0
    self.position = max + 1
  end

  def calculate_score
    self.score = score_for_position(position.to_i)
  end

  def create_activity
    if up?
      ActivityEndorsementNew.create(user: user, priority: priority)
    else
      ActivityOppositionNew.create(user: user, priority: priority)
    end
  end

  # Recompute denormalized counts from the actual rows. Robust against flips,
  # status changes and deletes (no fragile +1/-1 bookkeeping).
  def sync_counts
    refresh_counts_for_priority
    refresh_counts_for_user
    mark_official_status
    priority.update_columns(is_controversial: priority.reload.is_controversial?)
    priority.recalculate_score!
    Priority.recalculate_positions!
  end

  def refresh_counts_for_priority
    scope = Endorsement.where(priority_id: priority_id, status: "active")
    Priority.where(id: priority_id).update_all(
      "endorsements_count = #{scope.count}, " \
      "up_endorsements_count = #{scope.where('value > 0').count}, " \
      "down_endorsements_count = #{scope.where('value < 0').count}"
    )
  end

  def refresh_counts_for_user
    scope = Endorsement.where(user_id: user_id, status: "active")
    User.where(id: user_id).update_all(
      "endorsements_count = #{scope.count}, " \
      "up_endorsements_count = #{scope.where('value > 0').count}, " \
      "down_endorsements_count = #{scope.where('value < 0').count}"
    )
  end

  # If the official leader endorses/opposes, flag the priority accordingly.
  def mark_official_status
    return unless user_id == Government.current.official_user_id
    priority.update_columns(official_value: active? ? (up? ? 1 : -1) : 0)
  end
end
