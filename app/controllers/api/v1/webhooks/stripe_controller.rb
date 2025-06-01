class Api::V1::Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  before_action :verify_stripe_signature

  def create
    event_type = @event["type"]

    Rails.logger.info "Received Stripe webhook: #{event_type}"

    # Process webhook asynchronously
    StripeWebhookJob.perform_later(@event)

    render json: { received: true }, status: :ok
  rescue JSON::ParserError => e
    Rails.logger.error "Invalid JSON in Stripe webhook: #{e.message}"
    render json: { error: "Invalid JSON" }, status: :bad_request
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.error "Invalid Stripe signature: #{e.message}"
    render json: { error: "Invalid signature" }, status: :bad_request
  rescue => e
    Rails.logger.error "Error processing Stripe webhook: #{e.message}"
    render json: { error: "Internal server error" }, status: :internal_server_error
  end

  private

  def verify_stripe_signature
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    endpoint_secret = Rails.application.credentials.stripe[:webhook_secret]

    unless endpoint_secret
      Rails.logger.error "Stripe webhook secret not configured"
      render json: { error: "Webhook not configured" }, status: :internal_server_error
      return
    end

    begin
      @event = Stripe::Webhook.construct_event(
        payload,
        sig_header,
        endpoint_secret
      )
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Stripe signature verification failed: #{e.message}"
      render json: { error: "Invalid signature" }, status: :bad_request
      return
    end

    # Log the event for debugging
    Rails.logger.info "Stripe webhook verified: #{@event['type']} - #{@event['id']}"
  end
end
