class Vote < ApplicationRecord
  belongs_to :change
  belongs_to :user

  validates :user_id, uniqueness: { scope: :change_id }

  def yes? = value.to_i.positive?
  def no?  = !yes?
end
