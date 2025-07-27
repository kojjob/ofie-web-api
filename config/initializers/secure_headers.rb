# SecureHeaders configuration for enhanced security
SecureHeaders::Configuration.default do |config|
  # Content Security Policy
  config.csp = {
    default_src: %w['self'],
    font_src: %w['self' data: https://fonts.gstatic.com],
    img_src: %w['self' data: https: blob:],
    script_src: %w['self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com https://maps.googleapis.com],
    style_src: %w['self' 'unsafe-inline' https://fonts.googleapis.com],
    connect_src: %w['self' wss: https://api.stripe.com https://*.googleapis.com],
    frame_src: %w['self' https://js.stripe.com https://hooks.stripe.com],
    frame_ancestors: %w['none'],
    object_src: %w['none'],
    base_uri: %w['self'],
    form_action: %w['self'],
    report_uri: %w[/csp-report]
  }

  # Strict Transport Security
  config.hsts = "max-age=31536000; includeSubDomains; preload"

  # Prevent clickjacking
  config.x_frame_options = "DENY"

  # Prevent MIME type sniffing
  config.x_content_type_options = "nosniff"

  # Enable XSS protection
  config.x_xss_protection = "1; mode=block"

  # Control information sent in Referrer header
  config.referrer_policy = %w[strict-origin-when-cross-origin]


  # Public Key Pinning (optional - requires careful management)
  # config.hpkp = {
  #   report_only: false,
  #   max_age: 60.days.to_i,
  #   include_subdomains: true,
  #   report_uri: "https://report-uri.io/example",
  #   pins: [
  #     {sha256: "abc123"},
  #     {sha256: "def456"}
  #   ]
  # }
end

# Override for development environment
if Rails.env.development?
  SecureHeaders::Configuration.override(:development) do |config|
    config.csp[:script_src] << "'unsafe-eval'"
    config.csp[:connect_src] << "ws://localhost:*"
    config.hsts = SecureHeaders::OPT_OUT
  end
end

# Override for API endpoints (more permissive CSP)
SecureHeaders::Configuration.named_append(:api) do |config|
  config.csp[:default_src] = %w[*]
  config.csp[:script_src] = %w[*]
  config.csp[:connect_src] = %w[*]
end