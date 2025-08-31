ENV["RAILS_ENV"] ||= "test"

# SimpleCov must be started before any of your application code is required
require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/db/"

  add_group "Controllers", "app/controllers"
  add_group "Models", "app/models"
  add_group "Services", "app/services"
  add_group "Helpers", "app/helpers"
  add_group "Mailers", "app/mailers"
  add_group "Jobs", "app/jobs"
  add_group "Policies", "app/policies"
  add_group "Serializers", "app/serializers"

  minimum_coverage 80
  minimum_coverage_by_file 60

  formatter SimpleCov::Formatter::HTMLFormatter
end

require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"
require "factory_bot_rails"
require "faker"
require "database_cleaner/active_record"
require "webmock/minitest"
require "vcr"
require "timecop"
require "shoulda/matchers"
require "capybara/rails"
require "capybara/minitest"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Temporarily disabled due to foreign key constraint issues
    fixtures :all

    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Database cleaner setup
    DatabaseCleaner.strategy = :transaction

    setup do
      DatabaseCleaner.start
    end

    teardown do
      DatabaseCleaner.clean
      Timecop.return
    end

    # Helper method for JWT authentication in tests
    def auth_headers(user)
      token = JsonWebToken.encode(user_id: user.id)
      { "Authorization" => "Bearer #{token}" }
    end

    # Helper method for creating authenticated requests
    def authenticated_request(user, method, path, params = {})
      send(method, path, params: params, headers: auth_headers(user))
    end

    # Helper to parse JSON responses
    def json_response
      JSON.parse(@response.body)
    end
  end
end

# VCR configuration
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.allow_http_connections_when_no_cassette = false
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [ :method, :uri, :body ]
  }

  # Filter sensitive data
  config.filter_sensitive_data("<STRIPE_KEY>") { ENV["STRIPE_API_KEY"] }
  config.filter_sensitive_data("<JWT_SECRET>") { ENV["JWT_SECRET_KEY"] }
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

# Capybara configuration
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.save_path = Rails.root.join("tmp/capybara")

# WebMock configuration
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [ "chromedriver.storage.googleapis.com" ]
)
