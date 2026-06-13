ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Helper to build a saved user quickly.
    def create_user(login, attrs = {})
      User.create!({
        login: login,
        email_address: "#{login}@example.com",
        password: "password123",
        password_confirmation: "password123",
        status: "active"
      }.merge(attrs))
    end
  end
end
