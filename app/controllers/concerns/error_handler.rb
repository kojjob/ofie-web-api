module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError, with: :handle_standard_error
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_unprocessable_entity
    rescue_from ActiveRecord::RecordNotUnique, with: :handle_conflict
    rescue_from ActionController::ParameterMissing, with: :handle_bad_request
    rescue_from JWT::DecodeError, with: :handle_unauthorized
    rescue_from JWT::ExpiredSignature, with: :handle_token_expired

    # Stripe errors
    rescue_from Stripe::CardError, with: :handle_card_error
    rescue_from Stripe::InvalidRequestError, with: :handle_stripe_invalid_request
    rescue_from Stripe::AuthenticationError, with: :handle_stripe_authentication_error
    rescue_from Stripe::APIConnectionError, with: :handle_stripe_api_error
    rescue_from Stripe::StripeError, with: :handle_stripe_error

    # Custom application errors
    rescue_from AuthenticationError, with: :handle_unauthorized
    rescue_from AuthorizationError, with: :handle_forbidden
    rescue_from ValidationError, with: :handle_validation_error
    rescue_from ServiceError, with: :handle_service_error
  end

  private

  def handle_standard_error(error)
    log_error(error)

    if Rails.env.production?
      render_error("An error occurred. Please try again later.", :internal_server_error)
    else
      render_error(error.message, :internal_server_error, { backtrace: error.backtrace[0..10] })
    end
  end

  def handle_not_found(error)
    resource = error.model || "Resource"
    render_error("#{resource} not found", :not_found)
  end

  def handle_unprocessable_entity(error)
    render_error(
      "Validation failed",
      :unprocessable_entity,
      { details: error.record.errors.full_messages }
    )
  end

  def handle_conflict(error)
    render_error("Record already exists", :conflict)
  end

  def handle_bad_request(error)
    render_error("Bad request: #{error.message}", :bad_request)
  end

  def handle_unauthorized(error = nil)
    message = error&.message || "Authentication required"
    render_error(message, :unauthorized)
  end

  def handle_token_expired(error)
    render_error("Token has expired. Please login again.", :unauthorized)
  end

  def handle_forbidden(error = nil)
    message = error&.message || "You don't have permission to perform this action"
    render_error(message, :forbidden)
  end

  def handle_validation_error(error)
    render_error(
      "Validation error",
      :unprocessable_entity,
      { details: error.errors }
    )
  end

  def handle_service_error(error)
    render_error(error.message, :unprocessable_entity, error.details)
  end

  # Stripe error handlers
  def handle_card_error(error)
    render_error(
      "Card error: #{error.message}",
      :payment_required,
      { code: error.code, decline_code: error.decline_code }
    )
  end

  def handle_stripe_invalid_request(error)
    log_error(error)
    render_error("Invalid payment request", :bad_request)
  end

  def handle_stripe_authentication_error(error)
    log_error(error)
    render_error("Payment authentication failed", :unauthorized)
  end

  def handle_stripe_api_error(error)
    log_error(error)
    render_error("Payment service unavailable. Please try again later.", :service_unavailable)
  end

  def handle_stripe_error(error)
    log_error(error)
    render_error("Payment processing error", :internal_server_error)
  end

  # Helper methods
  def render_error(message, status, additional_data = {})
    error_response = {
      error: {
        message: message,
        status: status,
        timestamp: Time.current.iso8601,
        request_id: request.request_id
      }
    }

    error_response[:error].merge!(additional_data) if additional_data.present?

    # Track error in monitoring service
    track_error(message, status) if status == :internal_server_error

    respond_to do |format|
      format.json { render json: error_response, status: status }
      format.html do
        if status == :unauthorized
          redirect_to login_path, alert: message
        else
          redirect_back(fallback_location: root_path, alert: message)
        end
      end
    end
  end

  def log_error(error)
    Rails.logger.error "Error: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.backtrace

    # Send to error tracking service in production
    if Rails.env.production?
      Sentry.capture_exception(error) if defined?(Sentry)
    end
  end

  def track_error(message, status)
    # Track error metrics for monitoring
    Rails.logger.tagged("ERROR_METRICS") do
      Rails.logger.error({
        message: message,
        status: status,
        controller: controller_name,
        action: action_name,
        ip: request.remote_ip,
        user_agent: request.user_agent
      }.to_json)
    end
  end
end

# Custom error classes
class AuthenticationError < StandardError; end
class AuthorizationError < StandardError; end
class ValidationError < StandardError
  attr_reader :errors

  def initialize(message = "Validation failed", errors = [])
    @errors = errors
    super(message)
  end
end
class ServiceError < StandardError
  attr_reader :details

  def initialize(message, details = {})
    @details = details
    super(message)
  end
end
