# frozen_string_literal: false
#
# Facebook integration compatibility stubs.
#
# The application was built against Facebooker (Rails 2 era, Facebook Platform
# v1 — long dead). The Facebook features are inert without credentials:
# user_publisher.rb subclasses Facebooker::Rails::Publisher and the controllers
# gate Facebook work behind `facebook_session` checks.
#
# These stubs keep the constants loadable and make every Facebook call a no-op
# so the rest of the app runs. Real Facebook support would require rebuilding
# against the modern Graph API.

module Facebooker
  def self.api_key
    nil
  end

  def self.secret_key
    nil
  end

  def self.session(*_args)
    nil
  end

  class Session
    class SessionExpired < StandardError; end

    def self.from_session_key(*_args)
      nil
    end

    def user
      nil
    end
  end

  module Rails
    class Publisher
      class << self
        # Publisher template DSL (one_line_story_template, register_* etc.)
        def method_missing(_name, *_args, &_block)
          nil
        end

        def respond_to_missing?(_name, _include_private = false)
          true
        end
      end

      # Instance DSL used by publisher template methods
      def method_missing(_name, *_args, &_block)
        nil
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end
    end
  end
end
