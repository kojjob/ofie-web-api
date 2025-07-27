source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# JWT for authentication
gem "jwt"

# Payment processing with Stripe
gem "stripe"

# Email functionality for password reset and verification
gem "mail"

# OAuth integration
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-facebook"
gem "omniauth-rails_csrf_protection"

# Token generation for password reset and email verification
gem "securerandom"

# CSV processing for batch property uploads
gem "csv"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# Security enhancements
gem "rack-attack"
gem "secure_headers"

# API documentation
gem "rswag-api"
gem "rswag-ui"

# Background job monitoring
gem "sidekiq" # Alternative to solid_queue with better monitoring
gem "sidekiq-cron"

# Application monitoring
gem "sentry-ruby"
gem "sentry-rails"

# API versioning
gem "versionist"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
  
  # Factory pattern for test data
  gem "factory_bot_rails"
  
  # Generate fake data for tests
  gem "faker"
  
  # Stub HTTP requests in tests
  gem "webmock"
  
  # Record HTTP interactions for tests
  gem "vcr"
end

group :test do
  # Code coverage analysis
  gem "simplecov", require: false
  
  # Clean database between tests
  gem "database_cleaner-active_record"
  
  # Time travel for testing
  gem "timecop"
  
  # Better test assertions
  gem "shoulda-matchers"
  
  # Capybara for integration tests
  gem "capybara"
  gem "selenium-webdriver"
end

group :development do
  # Preview emails in browser during development
  gem "letter_opener"
  
  # N+1 query detection
  gem "bullet"
  
  # Better error pages
  gem "better_errors"
  gem "binding_of_caller"
  
  # Performance profiling
  gem "rack-mini-profiler"
  gem "memory_profiler"
  gem "stackprof"
  
  # Git hooks
  gem "lefthook"
  
  # Security audit
  gem "bundler-audit"
end

gem "kaminari", "~> 1.2"

gem "dockerfile-rails", ">= 1.7", group: :development
