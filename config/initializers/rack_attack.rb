# Rack::Attack configuration for rate limiting and security
class Rack::Attack
  # Cache store configuration (uses Rails cache)
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Safelist development and test environments
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end if Rails.env.development? || Rails.env.test?

  # General rate limiting - 300 requests per 5 minutes per IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets', '/packs')
  end

  # Strict rate limiting for authentication endpoints
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/api/v1/auth/login' && req.post?
      req.ip
    end
  end

  # Rate limit password reset requests
  throttle('password-reset/ip', limit: 5, period: 15.minutes) do |req|
    if req.path == '/api/v1/auth/password-reset' && req.post?
      req.ip
    end
  end

  # Rate limit registration
  throttle('registrations/ip', limit: 3, period: 15.minutes) do |req|
    if req.path == '/api/v1/auth/register' && req.post?
      req.ip
    end
  end

  # Rate limit API endpoints more strictly
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/api/')
  end

  # Rate limit property creation
  throttle('property-creation/user', limit: 10, period: 1.hour) do |req|
    if req.path == '/api/v1/properties' && req.post?
      req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    end
  end

  # Rate limit batch uploads
  throttle('batch-uploads/user', limit: 5, period: 1.day) do |req|
    if req.path.start_with?('/api/v1/batch_properties') && req.post?
      req.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    end
  end

  # Block suspicious requests
  blocklist('block-bad-agents') do |req|
    # Block requests with suspicious user agents
    req.user_agent =~ /bot|crawler|spider/i &&
      !req.user_agent.match?(/googlebot|bingbot|slackbot|twitterbot/i)
  end

  # Block requests trying to access sensitive files
  blocklist('block-sensitive-files') do |req|
    # List of sensitive file patterns to block
    sensitive_patterns = %w[
      .git .env wp-admin phpmyadmin config.php .htaccess
      web.config .DS_Store Thumbs.db .svn .hg
    ]
    
    sensitive_patterns.any? { |pattern| req.path.include?(pattern) }
  end

  # Custom response for rate limited requests
  self.throttled_responder = lambda do |env|
    retry_after = (env['rack.attack.match_data'] || {})[:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{
        error: 'Too Many Requests',
        message: 'Rate limit exceeded. Please try again later.',
        retry_after: retry_after
      }.to_json]
    ]
  end

  # Custom response for blocked requests
  self.blocklisted_responder = lambda do |env|
    [
      403,
      {
        'Content-Type' => 'application/json'
      },
      [{
        error: 'Forbidden',
        message: 'Your request has been blocked for security reasons.'
      }.to_json]
    ]
  end
end

# Enable Rack::Attack
Rails.application.config.middleware.use Rack::Attack

# Log blocked and throttled requests
ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
  req = payload[:request]
  
  Rails.logger.warn [
    'Rack::Attack:',
    req.env['rack.attack.match_type'],
    'for',
    req.ip,
    'path:',
    req.path,
    'user_agent:',
    req.user_agent
  ].join(' ')
end