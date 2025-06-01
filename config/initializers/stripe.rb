# Stripe configuration
require "stripe"

Rails.application.configure do
  # Set Stripe API key based on environment
  if Rails.application.credentials.stripe
    Stripe.api_key = Rails.application.credentials.stripe[:secret_key]

    # Set API version
    Stripe.api_version = "2023-10-16"

    # Configure logging in development
    if Rails.env.development?
      Stripe.log_level = Stripe::LEVEL_INFO
    end

    # Set webhook endpoint secret
    Rails.application.config.stripe_webhook_secret = Rails.application.credentials.stripe[:webhook_secret]

    # Set publishable key for frontend
    Rails.application.config.stripe_publishable_key = Rails.application.credentials.stripe[:publishable_key]

    Rails.logger.info "Stripe initialized with API version #{Stripe.api_version}"
  else
    Rails.logger.warn "Stripe credentials not found. Payment processing will not work."
  end
end

# Stripe configuration constants
module StripeConfig
  # Payment intent configuration
  PAYMENT_INTENT_DEFAULTS = {
    currency: "usd",
    automatic_payment_methods: {
      enabled: true
    },
    capture_method: "automatic"
  }.freeze

  # Setup intent configuration
  SETUP_INTENT_DEFAULTS = {
    usage: "off_session",
    automatic_payment_methods: {
      enabled: true
    }
  }.freeze

  # Customer configuration
  CUSTOMER_DEFAULTS = {
    preferred_locales: [ "en" ]
  }.freeze

  # Webhook events to handle
  WEBHOOK_EVENTS = [
    "payment_intent.succeeded",
    "payment_intent.payment_failed",
    "payment_intent.processing",
    "payment_intent.canceled",
    "payment_method.attached",
    "payment_method.detached",
    "customer.created",
    "customer.updated",
    "invoice.payment_succeeded",
    "invoice.payment_failed"
  ].freeze

  # Payment method types to support
  SUPPORTED_PAYMENT_METHODS = [
    "card",
    "us_bank_account"
  ].freeze

  # Late fee configuration
  LATE_FEE_CONFIG = {
    percentage: 0.05, # 5% of payment amount
    minimum_amount: 25.00, # Minimum $25 late fee
    maximum_amount: 100.00, # Maximum $100 late fee
    grace_period_days: 5 # 5 days grace period before late fee applies
  }.freeze
end
