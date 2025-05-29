Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2 configuration
  provider :google_oauth2,
    Rails.application.credentials.dig(:google, :client_id),
    Rails.application.credentials.dig(:google, :client_secret),
    {
      scope: "email,profile",
      prompt: "select_account",
      image_aspect_ratio: "square",
      image_size: 50
    }

  # Facebook OAuth configuration
  provider :facebook,
    Rails.application.credentials.dig(:facebook, :app_id),
    Rails.application.credentials.dig(:facebook, :app_secret),
    {
      scope: "email",
      info_fields: "email,name"
    }
end

# Configure OmniAuth settings
OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
