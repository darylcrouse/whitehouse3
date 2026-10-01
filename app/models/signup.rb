class Signup < ActiveRecord::Base

  belongs_to :user
  belongs_to :partner, :counter_cache => "users_count"

  # Transient optin flag posted with the signup form (see users#create,
  # partners#signup and the signups scaffold views); not persisted — the
  # persisted optin lives on Partner#is_optin.
  attr_accessor :is_optin

end
