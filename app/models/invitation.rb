class Invitation < ActiveRecord::Base
  include AASM

  scope :has_sender, -> { where("sender_id is not null") }
  
  belongs_to :user
  belongs_to :sender, :class_name => "User", :foreign_key => "sender_id"
  belongs_to :partner
  belongs_to :recipient, :class_name => "User", :foreign_key => "to_id"

  has_many :activities
  
  # docs: http://www.vaporbase.com/postings/stateful_authentication
  aasm column: :status, whiny_transitions: true do
    state :unsent, initial: true
    state :sent, after_enter: :do_send
    state :accepted, after_enter: :do_accept

    event :send do
      transitions from: :unsent, to: :sent
    end

    event :accept do
      transitions from: [:sent, :unsent], to: :accepted
    end
  end 
  
  validates_presence_of     :to_email, :unless => :has_facebook?
  validates_presence_of     :from_name
  #validates_presence_of    :to_name
  validates_length_of       :from_name,    :minimum => 3
  validates_length_of       :to_email,    :minimum => 3
  validates_format_of       :to_email, :with => /\A[-^!$#%&'*+\/=3D?`{|}~.\w]+@[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*(\.[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])*)+\z/x
  
  def has_facebook?
    attribute_present?("facebook_uid")
  end
  
end
