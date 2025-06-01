# Enhanced Routes for Intelligent Bot System
Rails.application.routes.draw do
  # API Routes
  namespace :api do
    namespace :v1 do
      # Bot routes
      scope :bot do
        post :send_message
        get :conversation_starters
        get :suggestions
        get :analytics
        post :feedback
        post :request_human_support
        get :personality_profile
      end

      # Enhanced property routes with bot integration
      resources :properties do
        member do
          post :favorite
          delete :unfavorite
          get :similar
          get :recommendations
          post :start_conversation
        end

        collection do
          get :trending
          get :personalized
          post :search_with_ai
        end

        resources :reviews, except: [ :show ]
        resources :viewings, except: [ :show ]
        resources :comments do
          resources :replies, controller: "comments"
        end
      end

      # Enhanced conversation routes
      resources :conversations do
        member do
          post :mark_as_read
          post :archive
          get :participants
        end

        resources :messages, except: [ :index ] do
          member do
            post :mark_as_read
            post :react
          end
        end
      end

      # User routes with preferences
      resources :users do
        member do
          get :preferences
          patch :update_preferences
          get :recommendations
          get :activity_summary
        end
      end

      # Enhanced application routes
      resources :rental_applications do
        member do
          post :submit
          post :withdraw
          post :approve
          post :reject
          get :documents
          post :upload_document
        end

        collection do
          get :requirements
          get :status_options
        end
      end

      # Maintenance routes with bot integration
      resources :maintenance_requests do
        member do
          post :assign
          post :update_status
          post :add_note
          post :mark_complete
        end

        collection do
          get :categories
          get :emergency_contacts
        end
      end

      # Payment routes
      resources :payments do
        member do
          post :process
          post :refund
        end

        collection do
          get :methods
          post :setup_autopay
        end
      end

      # Analytics and insights routes
      scope :analytics do
        get :property_insights
        get :user_behavior
        get :bot_performance
        get :market_trends
      end

      # Notification routes
      resources :notifications, only: [ :index, :show, :update ] do
        collection do
          post :mark_all_as_read
          get :unread_count
        end
      end
    end
  end

  # WebSocket routes for real-time features
  mount ActionCable.server => "/cable"

  # Admin routes (if needed)
  namespace :admin do
    resources :bot_analytics, only: [ :index, :show ]
    resources :bot_training_data, only: [ :index, :show, :update ]
    resources :bot_feedback, only: [ :index, :show ]
  end

  # Root route
  root "home#index"

  # Demo routes for testing
  get "/demo/bot", to: "demo#bot"
  get "/demo/chat", to: "demo#chat"
end
