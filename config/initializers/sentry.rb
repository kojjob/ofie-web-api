# Sentry configuration for error monitoring
if Rails.env.production? || Rails.env.staging?
  Sentry.init do |config|
    config.dsn = ENV['SENTRY_DSN']
    config.breadcrumbs_logger = [:active_support_logger, :http_logger]
    
    # Performance monitoring
    config.traces_sample_rate = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE', '0.1').to_f
    config.profiles_sample_rate = ENV.fetch('SENTRY_PROFILES_SAMPLE_RATE', '0.1').to_f
    
    # Release tracking
    config.release = ENV['HEROKU_SLUG_COMMIT'] || ENV['GIT_COMMIT_SHA']
    
    # Environment
    config.environment = Rails.env
    
    # Filtering
    config.before_send = lambda do |event, hint|
      # Filter out sensitive data
      if event.request && event.request.data
        event.request.data = filter_sensitive_data(event.request.data)
      end
      
      # Don't send events for certain errors
      if hint[:exception].is_a?(ActiveRecord::RecordNotFound) ||
         hint[:exception].is_a?(ActionController::RoutingError)
        nil
      else
        event
      end
    end
    
    # Transaction filtering
    config.before_send_transaction = lambda do |event, hint|
      # Filter out health checks and asset requests
      if event.transaction_info && event.transaction_info[:source] == :url
        transaction_name = event.transaction_info[:name]
        
        if transaction_name.match?(/health|assets|packs|favicon/)
          nil
        else
          event
        end
      else
        event
      end
    end
    
    # Excluded exceptions
    config.excluded_exceptions += [
      'ActionController::UnknownFormat',
      'ActionController::BadRequest',
      'Rack::QueryParser::ParameterTypeError',
      'Rack::QueryParser::InvalidParameterError'
    ]
    
    # Set tracing to debug performance issues
    config.debug = false
    config.sample_rate = 1.0
    
    # Associate users
    config.send_default_pii = false
    
    # Background job integration
    config.async = lambda do |event, hint|
      Sentry::SendEventJob.perform_later(event, hint)
    end if defined?(Sentry::SendEventJob)
  end
  
  # Helper method to filter sensitive data
  def filter_sensitive_data(data)
    return data unless data.is_a?(Hash)
    
    sensitive_keys = %w[password password_confirmation token secret key api_key access_token refresh_token credit_card]
    
    data.transform_values do |value|
      if value.is_a?(Hash)
        filter_sensitive_data(value)
      elsif value.is_a?(String) && sensitive_keys.any? { |key| data.key?(key) }
        '[FILTERED]'
      else
        value
      end
    end
  end
end