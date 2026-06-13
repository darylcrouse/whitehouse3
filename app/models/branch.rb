class Branch < ApplicationRecord
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :most_active, -> { order(endorsements_count: :desc) }
end
