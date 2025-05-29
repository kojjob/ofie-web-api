Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "/auth/login", to: "auth#login"
      post "/auth/register", to: "auth#register"
      post "/auth/logout", to: "auth#logout"
      get "/auth/me", to: "auth#me"

      # Enhanced authentication routes
      post "/auth/refresh", to: "auth#refresh_token"
      post "/auth/verify_email", to: "auth#verify_email"
      post "/auth/resend_verification", to: "auth#resend_verification"
      post "/auth/forgot_password", to: "auth#forgot_password"
      post "/auth/reset_password", to: "auth#reset_password"

      # OAuth callback routes
      get "/auth/google/callback", to: "auth#google_callback"
      get "/auth/facebook/callback", to: "auth#facebook_callback"

      # Properties routes with nested resources
      resources :properties, only: [ :index, :show, :create, :update, :destroy ] do
        # Property favorites
        resource :favorites, controller: "property_favorites", only: [ :create, :destroy ]

        # Property viewings
        resources :viewings, controller: "property_viewings", only: [ :create ]

        # Property reviews
        resources :reviews, controller: "property_reviews", only: [ :index, :create ]
      end

      # Standalone property feature routes
      resources :property_favorites, only: [ :index ]
      resources :property_viewings, only: [ :index, :show, :update, :destroy ]
      resources :property_reviews, only: [ :show, :update, :destroy ] do
        member do
          post :helpful, to: "property_reviews#mark_helpful"
        end
      end

      # User-specific routes
      get "/users/:user_id/reviews", to: "property_reviews#user_reviews"
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
      get :search
    end
    member do
      delete :remove_photo
    end
  end

  # Notification routes
  resources :notifications, only: [ :index, :show ] do
    member do
      patch :mark_read
    end
    collection do
      patch :mark_all_read
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Flash Message Demo
  get "/demo/flash", to: "demo#flash_demo", as: "demo_flash_demo"
  post "/demo/test/success", to: "demo#test_success", as: "demo_test_success"
  post "/demo/test/error", to: "demo#test_error", as: "demo_test_error"
  post "/demo/test/warning", to: "demo#test_warning", as: "demo_test_warning"
  post "/demo/test/info", to: "demo#test_info", as: "demo_test_info"
  post "/demo/test/notice", to: "demo#test_notice", as: "demo_test_notice"
  post "/demo/test/alert", to: "demo#test_alert", as: "demo_test_alert"
  post "/demo/test/multiple", to: "demo#test_multiple", as: "demo_test_multiple"

  # Health check
  get "/health", to: "application#health"

  # Defines the root path route ("/")
  root "properties#index"
end
