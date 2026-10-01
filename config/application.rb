require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Whitehouse2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks core_extensions.rb diff.rb sgml_parser.rb html2textile.rb validates_uri_existence_of.rb))

    # Legacy controllers reference callback actions that no longer exist
    # (e.g. `before_action :setup, :except => [:partner]` on a controller
    # whose action is `partners`). Rails 7.1+ raises on those by default,
    # which 404s whole controllers; keep the pre-7.1 tolerance.
    config.action_controller.raise_on_missing_callback_actions = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
