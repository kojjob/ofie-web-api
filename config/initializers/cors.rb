# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # Get allowed origins from environment variable or use defaults
  allowed_origins = if Rails.env.production?
    ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip)
  else
    # Development origins
    %w[
      http://localhost:3000
      http://localhost:3001
      http://127.0.0.1:3000
      http://127.0.0.1:3001
      http://localhost:5173
      http://localhost:5174
    ]
  end

  allow do
    origins *allowed_origins

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true,
      max_age: 86400,
      expose: [ "X-Total-Count", "X-Page", "X-Per-Page" ]
  end

  # Specific configuration for OAuth callbacks in production
  if Rails.env.production?
    allow do
      origins "https://accounts.google.com", "https://www.facebook.com", "https://facebook.com"

      resource "/api/v1/auth/oauth/*",
        headers: :any,
        methods: [ :get, :post, :options ],
        credentials: true,
        max_age: 86400
    end
  end

  # Health check endpoint - allow from monitoring services
  allow do
    origins "*"

    resource "/health",
      headers: :any,
      methods: [ :get, :head ],
      credentials: false
  end
end
