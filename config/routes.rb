Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/refresh", to: "auth#refresh_token"

      # Email verification routes
      get "auth/verify/:token", to: "auth#verify_email", as: "verify_email"
      post "auth/resend_verification", to: "auth#resend_verification"

      # Password reset routes
      post "auth/password_reset", to: "auth#request_password_reset"
      patch "auth/password_reset/:token", to: "auth#reset_password", as: "reset_password"

      # OAuth routes
      get "auth/:provider/callback", to: "auth#:provider", constraints: { provider: /google_oauth2|facebook/ }

      # User profile routes
      get "profile", to: "users#show"
      patch "profile", to: "users#update"

      # Property routes for API
      resources :properties do
        collection do
          get :my_properties
        end
      end
    end
  end

  # Web routes (for both API and potential web interface)
  # Authentication routes
  get "login", to: "auth#login_form", as: "login"
  post "login", to: "auth#login"
  get "register", to: "auth#register_form", as: "register"
  post "register", to: "auth#register"
  delete "logout", to: "auth#logout", as: "logout"

  # API routes for backward compatibility
  post "auth/register", to: "auth#register"
  post "auth/login", to: "auth#login"

  # Property routes for web/API
  resources :properties do
    collection do
      get :my_properties
    end
    member do
      delete :remove_photo
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "properties#index"
end
