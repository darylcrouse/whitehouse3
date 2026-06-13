# A Priority is the central object: a thing people think the government should do.
# Users endorse (up) or oppose (down) it and rank it within their own list. The
# aggregate, weighted score determines its global position on the leaderboard.
class Priority < ApplicationRecord
  MAX_POSITION = 100

  belongs_to :user, optional: true

  has_many :endorsements, dependent: :destroy
  has_many :endorsers, through: :endorsements, source: :user
  has_many :points, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :change_proposals, class_name: "Change", dependent: :destroy
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  validates :name, presence: true, length: { within: 3..140 }, uniqueness: { case_sensitive: false }

  before_validation :set_published_at, on: :create
  after_create :create_debut_activity

  scope :published,      -> { where(status: "published") }
  scope :top_rank,       -> { order(score: :desc, position: :asc) }
  scope :rising,         -> { where("trending_score > 0").order(trending_score: :desc) }
  scope :falling,        -> { where("trending_score < 0").order(trending_score: :asc) }
  scope :controversial,  -> { where(is_controversial: true).order(controversial_score: :desc) }
  scope :newest,         -> { order(Arel.sql("COALESCE(published_at, created_at) DESC")) }
  scope :alphabetical,   -> { order(name: :asc) }
  scope :finished,       -> { where("official_status IN (-2,-1,2)") }
  scope :official_endorsed, -> { where("official_value > 0") }
  scope :untagged,       -> { where("cached_issue_list IS NULL OR cached_issue_list = ''") }

  def to_param
    "#{id}-#{name.parameterize}"
  end

  def published?
    %w[published inactive].include?(status)
  end

  def is_new?
    created_at.nil? || created_at > 7.days.ago
  end

  # Up/Down endorsement helpers -------------------------------------------------

  def endorse(user, request = nil)
    return false unless user
    e = endorsements.find_by(user_id: user.id)
    if e.nil?
      e = endorsements.create(value: 1, user: user, ip_address: request&.remote_ip)
    elsif e.down? || !e.active?
      e.update(value: 1, status: "active") # counts re-synced by callbacks
    end
    e
  end

  def oppose(user, request = nil)
    return false unless user
    e = endorsements.find_by(user_id: user.id)
    if e.nil?
      e = endorsements.create(value: -1, user: user, ip_address: request&.remote_ip)
    elsif e.up? || !e.active?
      e.update(value: -1, status: "active") # counts re-synced by callbacks
    end
    e
  end

  def unendorse(user)
    endorsements.find_by(user_id: user.id)&.destroy
  end

  # Scoring ---------------------------------------------------------------------

  # Aggregate weighted score: sum of each active endorsement's score.
  def recalculate_score!
    total = endorsements.where(status: "active").sum(:score)
    update_columns(score: total, updated_at: Time.current)
  end

  # Rebuild the global leaderboard positions for all published priorities.
  def self.recalculate_positions!
    published.top_rank.each_with_index do |priority, index|
      pos = index + 1
      priority.update_columns(position: pos) unless priority.position == pos
    end
  end

  def is_controversial?
    return false unless up_endorsements_count.positive? && down_endorsements_count.positive?
    ratio = up_endorsements_count.to_f / down_endorsements_count
    ratio > 0.5 && ratio < 2
  end

  # Tagging ---------------------------------------------------------------------

  def issue_list
    (cached_issue_list || "").split(",").map(&:strip).reject(&:blank?)
  end

  def issue_list=(names)
    names = names.split(",") if names.is_a?(String)
    names = names.map { |n| n.to_s.strip }.reject(&:blank?).uniq
    taggings.destroy_all
    names.each do |tname|
      tag = Tag.find_or_create_by(slug: tname.parameterize) do |tg|
        tg.name = tname
        tg.title = tname
      end
      taggings.create(tag: tag)
    end
    self.cached_issue_list = names.join(",")
  end

  def has_tags?
    cached_issue_list.present?
  end

  # Related priorities sharing tags.
  def related(limit = 8)
    return Priority.none if tags.empty?
    Priority.published
            .where.not(id: id)
            .joins(:taggings)
            .where(taggings: { tag_id: tags.ids })
            .group("priorities.id")
            .order(Arel.sql("COUNT(taggings.id) DESC, priorities.endorsements_count DESC"))
            .limit(limit)
  end

  # Official ("Obama") status ---------------------------------------------------

  STATUS_LABELS = {
    -2 => "Failed", -1 => "Compromised", 0 => "Not yet decided",
    1 => "In the works", 2 => "Successful"
  }.freeze

  def official_status_name
    STATUS_LABELS[official_status]
  end

  def finished?
    official_status > 1 || official_status.negative?
  end

  private

  def set_published_at
    self.published_at ||= Time.current if status == "published"
  end

  def create_debut_activity
    ActivityPriorityNew.create(user: user, priority: self) if user
  end
end
