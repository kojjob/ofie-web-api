module Users
  class RegistrationService < ApplicationService
    def initialize(params:, send_verification: true)
      @params = params
      @send_verification = send_verification
    end

    def call
      with_transaction do
        user = build_user

        if user.save
          create_stripe_customer(user) if user.landlord?
          send_verification_email(user) if @send_verification
          create_welcome_notification(user)
          track_registration(user)

          log_execution("User registered: #{user.id}")
          success(user: user, token: generate_token(user))
        else
          failure(user.errors.full_messages)
        end
      end
    end

    private

    attr_reader :params, :send_verification

    def build_user
      User.new(user_params)
    end

    def user_params
      params.slice(:email, :password, :password_confirmation, :name, :role, :phone)
            .merge(email_verified: false)
    end

    def create_stripe_customer(user)
      stripe_customer = Stripe::Customer.create(
        email: user.email,
        name: user.name,
        metadata: {
          user_id: user.id,
          role: user.role
        }
      )

      user.update_column(:stripe_customer_id, stripe_customer.id)
    rescue Stripe::StripeError => e
      log_execution("Stripe customer creation failed: #{e.message}", :error)
      # Don't fail the registration if Stripe fails
    end

    def send_verification_email(user)
      user.generate_email_verification_token
      UserMailer.email_verification(user).deliver_later
    rescue StandardError => e
      log_execution("Verification email failed: #{e.message}", :error)
    end

    def create_welcome_notification(user)
      Notification.create!(
        user: user,
        title: "Welcome to Property Management!",
        message: "Thank you for joining. Complete your profile to get started.",
        notification_type: "system",
        priority: "low"
      )
    rescue StandardError => e
      log_execution("Welcome notification failed: #{e.message}", :warn)
    end

    def track_registration(user)
      # Track registration event for analytics
      AnalyticsTracker.track(
        event: "user_registered",
        user_id: user.id,
        properties: {
          role: user.role,
          source: params[:source] || "web"
        }
      )
    rescue StandardError => e
      log_execution("Analytics tracking failed: #{e.message}", :warn)
    end

    def generate_token(user)
      User.encode_token(user_id: user.id)
    end
  end
end
