class Current < ActiveSupport::CurrentAttributes
  attribute :session, :government
  delegate :user, to: :session, allow_nil: true
end
