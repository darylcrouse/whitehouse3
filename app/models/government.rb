# Singleton configuration for the deployment. In the original White House 2 this
# supported many "governments" per install; here a single row holds site config.
class Government < ApplicationRecord
  belongs_to :official_user, class_name: "User", optional: true

  def self.current
    Current.government ||= first_or_create!(name: "White House", tagline: "A government of the people, by the people")
  end

  def branches?
    is_branches?
  end

  def tags?
    is_tags?
  end
end
