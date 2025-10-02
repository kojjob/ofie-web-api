# Configure SimpleCov before loading Rails
require "simplecov"
SimpleCov.start "rails" do
  # Set minimum coverage threshold
  minimum_coverage 85
  minimum_coverage_by_file 80

  # Exclude non-application code
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/db/"

  # Coverage for specific groups
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Helpers", "app/helpers"
  add_group "Policies", "app/policies"
  add_group "Serializers", "app/serializers"

  # Track branches for more thorough coverage
  enable_coverage :branch

  formatter SimpleCov::Formatter::HTMLFormatter
end

ENV["RAILS_ENV"] ||= "test"
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

# WebMock configuration
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: [ "chromedriver.storage.googleapis.com" ]
)

# Load test support files
Dir[Rails.root.join("test/support/**/*.rb")].each { |f| require f }

module ActiveSupport
  class TestCase
    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Include Stripe test helpers
    include StripeHelpers

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Database cleaner setup
    DatabaseCleaner.strategy = :transaction

    setup do
      DatabaseCleaner.start
    end

    teardown do
      DatabaseCleaner.clean
      Timecop.return
    end

    # Use FactoryBot instead of fixtures for test data
    # fixtures :all # Disabled - using FactoryBot factories instead

    # Add more helper methods to be used by all tests here...

    # Helper method to generate JWT token for authentication tests
    def generate_jwt_token(user)
      JWT.encode(
        {
          user_id: user.id,
          email: user.email,
          exp: 24.hours.from_now.to_i
        },
        Rails.application.credentials.jwt_secret_key || "test_secret_key"
      )
    end

    # Helper method to create authorization header
    def auth_header(user)
      { "Authorization" => "Bearer #{generate_jwt_token(user)}" }
    end

    # Alternative helper method for JWT authentication (from main)
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

    # Helper to assert service result success
    def assert_service_success(result, message = nil)
      assert result.success?, message || "Expected service to succeed, but got errors: #{result.errors&.full_messages&.join(', ')}"
    end

    # Helper to assert service result failure
    def assert_service_failure(result, message = nil)
      assert_not result.success?, message || "Expected service to fail, but it succeeded"
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
