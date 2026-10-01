ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "../lib/authenticated_test_helper"
require_relative "support/legacy_test_data"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers (SQLite + heavy boot: 4 is a
  # better trade-off than one worker DB per core).
  parallelize(workers: 4)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Every legacy page assumes the singleton Government exists (without it the
  # app redirects everything to /install). Built inside each test's transaction.
  setup do
    LegacyTestData.reset!
    LegacyTestData.ensure!
    # `fixtures :users` in the 2009 tests assumed quentin/aaron pre-exist.
    LegacyTestData.fixture('users', :quentin)
    LegacyTestData.fixture('users', :aaron)
  end

  # Log the admin user into the controller-test session (2009 tests predate the
  # login/admin gates the app later grew).
  def login_as_user(user = nil)
    @request.session[:user_id] = (user || LegacyTestData.admin).id
  end

  # Rails-2 fixture accessors — `priorities(:one)`, `users(:quentin)` — resolve
  # to rows built on demand (this repo carries no fixture YAMLs).
  def method_missing(name, *args)
    if args.size == 1 && args.first.is_a?(Symbol) && LegacyTestData.fixture_model?(name)
      LegacyTestData.fixture(name, args.first)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    LegacyTestData.fixture_model?(name) || super
  end
end
