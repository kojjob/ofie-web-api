# Cache configuration
Rails.application.configure do
  # Use Solid Cache (Rails 8 default) for production
  # In development, use memory store for simplicity
  if Rails.env.production?
    config.cache_store = :solid_cache_store
  elsif Rails.env.development?
    config.cache_store = :memory_store, { size: 64.megabytes }
  else
    config.cache_store = :null_store
  end

  # Enable caching in development if ENABLE_CACHE is set
  if Rails.env.development? && ENV["ENABLE_CACHE"].present?
    config.action_controller.perform_caching = true
    # Use Solid Cache in development when caching is enabled
    config.cache_store = :solid_cache_store
  end
end

# Cache key configuration
module CacheKeys
  # Property-related cache keys
  FEATURED_PROPERTIES = "featured_properties"
  RECENT_PROPERTIES = "recent_properties"
  PROPERTY_COUNT = "property_count"

  # User-related cache keys
  USER_PROPERTIES = ->(user_id) { "user_#{user_id}_properties" }
  USER_FAVORITES = ->(user_id) { "user_#{user_id}_favorites" }
  USER_DASHBOARD = ->(user_id) { "user_#{user_id}_dashboard" }

  # Search-related cache keys
  SEARCH_RESULTS = ->(query_hash) { "search_#{query_hash}" }
  LOCATION_PROPERTIES = ->(location) { "location_#{location.parameterize}_properties" }

  # Payment-related cache keys
  PAYMENT_SUMMARY = ->(user_id) { "payment_summary_#{user_id}" }
  MONTHLY_REVENUE = ->(year, month) { "revenue_#{year}_#{month}" }

  # Analytics cache keys
  ANALYTICS_DASHBOARD = "analytics_dashboard"
  PROPERTY_STATISTICS = "property_statistics"
end

# Cache expiration times
module CacheExpiration
  SHORT = 5.minutes
  MEDIUM = 30.minutes
  LONG = 1.hour
  VERY_LONG = 6.hours
  DAILY = 24.hours
end
