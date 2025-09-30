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

  # Coverage for specific groups
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Helpers", "app/helpers"

  # Track branches for more thorough coverage
  enable_coverage :branch
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "bcrypt"

# Load FactoryBot
require "factory_bot_rails"

# Load WebMock for HTTP request stubbing
require "webmock/minitest"
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

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
