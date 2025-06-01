require_relative "boot"

require "rails/all"

# Load CSV library for batch property uploads
# Try multiple approaches to load CSV
begin
  require "csv"
rescue LoadError
  begin
    # Try loading from standard library
    require "csv"
  rescue LoadError
    # CSV will be handled with fallback methods
    Rails.logger.warn "CSV library not available, will use fallback methods"
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module OfieWebApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Add builds directory to asset paths for Tailwind CSS
    config.assets.paths << Rails.root.join("app/assets/builds")

    # Enable asset pipeline for frontend functionality
    # We're adding web views alongside API endpoints
    # config.api_only = true
  end
end
