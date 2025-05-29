Rails.application.routes.draw do
  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"

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
