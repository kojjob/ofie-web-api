Rails.application.routes.draw do
  # Health check endpoint
  get "/health", to: "health#show"

  # CSP Report endpoint
  post "/csp-report", to: "csp_reports#create"

  # SEO routes
  get "/sitemap.xml", to: "sitemap#index", defaults: { format: "xml" }

  # API routes
  namespace :api do
    # Non-versioned API endpoints
    resources :property_inquiries, only: [ :create ]

    namespace :v1 do
      # Authentication routes
      post "/auth/login", to: "auth#login"
      post "/auth/register", to: "auth#register"
      post "/auth/logout", to: "auth#logout"
      get "/auth/me", to: "auth#me"

      # Enhanced authentication routes
      post "/auth/refresh", to: "auth#refresh_token"
      get "/auth/verify_email", to: "auth#verify_email", as: :verify_email
      post "/auth/verify_email", to: "auth#verify_email"
      post "/auth/resend_verification", to: "auth#resend_verification"
      get "/auth/forgot_password", to: "auth#forgot_password"
      post "/auth/forgot_password", to: "auth#forgot_password"
      get "/auth/reset_password", to: "auth#reset_password"
      patch "/auth/reset_password", to: "auth#reset_password"

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

        # Property comments
        resources :comments, controller: "property_comments", only: [ :index, :create ]

        # Maintenance requests
        resources :maintenance_requests, only: [ :index, :create ]
      end

      # Standalone property feature routes
      resources :property_favorites, only: [ :index ]
      resources :property_viewings, only: [ :index, :show, :update, :destroy ]
      resources :property_reviews, only: [ :show, :update, :destroy ] do
        member do
          post :helpful, to: "property_reviews#mark_helpful"
        end
      end

      resources :property_comments, only: [ :show, :update, :destroy ] do
        member do
          post :toggle_like
          post :flag
        end
      end

      # User-specific routes
      get "/users/:user_id/reviews", to: "property_reviews#user_reviews"

      # User profile and settings routes
      get "/profile", to: "users#show"
      get "/profile/edit", to: "users#edit"
      patch "/profile", to: "users#update"
      get "/settings", to: "users#settings"
      patch "/settings", to: "users#update_settings"
      patch "/change_password", to: "users#change_password", as: :change_password

      # Payment routes
      resources :payments, only: [ :index, :show, :create ] do
        member do
          post :retry
          post :cancel
        end
        collection do
          get :summary
        end
      end

      # Payment methods routes
      resources :payment_methods, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post :make_default
        end
        collection do
          post :setup_intent_success
          get :validate
        end
      end

      # Payment schedules routes
      resources :payment_schedules, only: [ :index, :show, :update, :destroy ] do
        member do
          post :activate
          post :deactivate
          post :toggle_auto_pay
          post :create_payment
        end
        collection do
          get :upcoming
        end
      end

      # Lease agreements with nested payment resources
      resources :lease_agreements, only: [ :index, :show, :create, :update ] do
        resources :payments, only: [ :index, :create ]
        resources :payment_schedules, only: [ :index, :create ]
      end

      # Rental applications routes
      resources :rental_applications, only: [ :index, :show, :create, :update ] do
        member do
          post :approve
          post :reject
          post :under_review
          post :generate_lease
        end
      end

      # Security deposits routes
      resources :security_deposits, only: [ :index, :show, :update ] do
        member do
          post :mark_collected
          post :process_refund
          post :add_deduction
        end
      end

      # Maintenance requests routes
      resources :maintenance_requests, only: [ :index, :show, :update, :destroy ] do
        member do
          post :complete
          post :schedule
        end
      end

      # Webhook routes
      namespace :webhooks do
        post :stripe, to: "stripe#create"
      end

      # Messaging routes
      resources :conversations, only: [ :index, :show, :new, :create, :update, :destroy ] do
        resources :messages, only: [ :index, :show, :create, :update, :destroy ] do
          member do
            patch :mark_read
          end
          collection do
            patch :mark_all_read
          end
        end
      end

      # Bot routes
      namespace :bot do
        post :chat
        post :start_conversation
        get :suggestions
        get :faqs
        post :feedback
      end

      # Rental Applications API routes
      get "rental_applications/approved", to: "rental_applications#approved_for_lease"
    end
  end

  # Web routes (for both API and potential web interface)
  # Authentication routes
  get "login", to: "auth#login_form", as: "login"
  post "login", to: "auth#login"
  get "register", to: "auth#register_form", as: "register"
  post "register", to: "auth#register"
  delete "logout", to: "auth#logout", as: "logout"
  get "logout", to: "auth#logout", as: "logout_get"
  get "forgot_password", to: "auth#forgot_password"
  post "forgot_password", to: "auth#forgot_password"
  get "reset_password", to: "auth#reset_password"
  patch "reset_password", to: "auth#reset_password"

  # User profile routes (Web)
  get "profile", to: "users#show", as: "profile"
  get "profile/edit", to: "users#edit", as: "edit_profile"
  patch "profile", to: "users#update"
  get "settings", to: "users#settings", as: "settings"
  patch "settings", to: "users#update_settings"
  patch "change_password", to: "users#change_password", as: "change_password"

  # Property routes for web/API
  # Add this to the properties resource
  resources :properties do
    collection do
      get :my_properties
      get :search
    end
    member do
      delete :remove_photo
    end
    # Add nested property_viewings routes
    resources :property_viewings, only: [ :new, :create, :show, :index, :update, :destroy ] do
      collection do
        get :available_slots
      end
    end

    # Add nested property_comments routes
    resources :property_comments, only: [ :index, :create ] do
      collection do
        get :recent
      end
    end

    # Add nested property_reviews routes
    resources :property_reviews, only: [ :index, :create ]

    # Add nested rental_applications routes
    resources :rental_applications, only: [ :new, :create ]
  end

  # Standalone property comments routes (Web)
  resources :property_comments, only: [ :show, :edit, :update, :destroy ] do
    member do
      post :toggle_like
      post :flag
    end
  end

  # Property reviews routes (Web)
  resources :property_reviews, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    member do
      patch :helpful
    end
  end

  # User reviews route
  get "/users/:user_id/reviews", to: "property_reviews#user_reviews", as: "user_reviews"

  # Notification routes
  resources :notifications, only: [ :index, :show ] do
    member do
      patch :mark_read
    end
    collection do
      patch :mark_all_read
      get :unread_count
    end
  end

  # Property Inquiries routes (Web - Landlord Management)
  resources :property_inquiries, only: [ :index, :show ] do
    member do
      post :mark_read
      post :mark_responded
      post :archive
      post :unarchive
    end
  end

  # Messaging routes
  resources :conversations, only: [ :index, :show, :new, :create, :update, :destroy ] do
    resources :messages, only: [ :index, :show, :create, :update, :destroy ] do
      member do
        patch :mark_read
      end
      collection do
        patch :mark_all_read
      end
    end
  end

  # Maintenance Request routes (Web)
  resources :maintenance_requests do
    member do
      post :complete
      post :schedule
    end
  end

  # Batch Properties routes (Web)
  resources :batch_properties, only: [ :index, :new, :show, :destroy ] do
    collection do
      get :template
      post :upload
    end
    member do
      get :preview
      post :process_batch
      post :fix_status
      post :retry_failed
      get :status
      get :results
      get "item_details/:item_id", action: :item_details, as: :item_details
      post "retry_item/:item_id", action: :retry_item, as: :retry_item
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

  # Dashboard routes
  get "/dashboard", to: "dashboard#index", as: "dashboard"
  get "/dashboard/landlord", to: "dashboard#landlord_dashboard", as: "landlord_dashboard"
  get "/dashboard/tenant", to: "dashboard#tenant_dashboard", as: "tenant_dashboard"
  get "/dashboard/analytics", to: "dashboard#analytics", as: "dashboard_analytics"

  # Analytics routes
  get "/analytics", to: "analytics#index", as: "analytics"

  # Favorites routes
  get "/favorites", to: "property_favorites#index", as: "favorites"

  # Rental Applications routes (Web)
  resources :rental_applications, only: [ :index, :show, :edit, :update, :destroy ] do
    member do
      get :approve
      post :approve
      get :reject
      post :reject
      get :under_review
      post :under_review
      post :generate_lease
    end

    # Nested lease agreements routes
    resources :lease_agreements, only: [ :new, :create ]
  end

  # Lease Agreements routes (Web)
  resources :lease_agreements, only: [ :index, :show, :edit, :update, :destroy ] do
    member do
      post :sign_tenant
      post :sign_landlord
      post :activate
      post :terminate
    end

    # Nested payments routes
    resources :payments, only: [ :new, :create ]
  end

  # Payments routes (Web)
  resources :payments, only: [ :index, :show ] do
    member do
      post :pay
      post :cancel
      post :refund
    end
  end

  # Home page
  get "/home", to: "home#index", as: "home"
  get "/about", to: "home#about", as: "about"
  get "/help", to: "home#help", as: "help"
  get "/contact", to: "home#contact", as: "contact"
  get "/terms_of_service", to: "home#terms_of_service", as: "terms_of_service"
  get "/privacy_policy", to: "home#privacy_policy", as: "privacy_policy"
  get "/cookie_policy", to: "home#cookie_policy", as: "cookie_policy"
  get "/accessibility", to: "home#accessibility", as: "accessibility"
  get "tenant_screening", to: "home#tenant_screening", as: "tenant_screening"

  # Newsletter and additional routes
  post "/newsletter/signup", to: "newsletter#create", as: "newsletter_signup"

  # Additional footer routes
  get "/calculators", to: "tools#calculators", as: "calculators"
  get "/neighborhoods", to: "home#neighborhoods", as: "neighborhoods"
  get "/resources/renters", to: "home#renter_resources", as: "resources_renters"
  get "/dashboard/properties", to: "dashboard#properties", as: "dashboard_properties"
  get "/market-analysis", to: "tools#market_analysis", as: "market_analysis"
  get "/landlord-tools", to: "tools#landlord_tools", as: "landlord_tools"
  get "/careers", to: "home#careers", as: "careers"
  get "/press", to: "home#press", as: "press"

  # Blog routes
  get "/blog", to: "blog#index", as: "blog_index"
  get "/blog/new", to: "blog#new", as: "new_blog_post"
  post "/blog", to: "blog#create"
  get "/blog/:slug", to: "blog#show", as: "blog_post"
  get "/blog/:slug/edit", to: "blog#edit", as: "edit_blog_post"
  patch "/blog/:slug", to: "blog#update"
  delete "/blog/:slug", to: "blog#destroy", as: "destroy_blog_post"

  # Defines the root path route ("/")
  root "home#index"
end
