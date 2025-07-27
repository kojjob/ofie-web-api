class ApplicationController < ActionController::Base
  # Security concerns
  include InputSanitizer
  
  # Skip CSRF protection for API requests
  protect_from_forgery with: :null_session
  
  # Request tracking
  before_action :set_request_id
  before_action :authenticate_request, unless: :web_request?
  
  # Error handling
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
  
  attr_reader :current_user
  helper_method :current_user, :user_signed_in?

  def user_signed_in?
    current_user.present?
  end

  def current_user
    @current_user ||= find_current_user
  end

  private

  def find_current_user
    if web_request? && session[:user_id]
      # For web requests (HTML, CSV, etc.), use session-based authentication
      User.find_by(id: session[:user_id])
    elsif !web_request?
      # For API requests, use JWT authentication
      authenticate_with_jwt
    end
  end

  def html_request?
    request.format.html?
  end

  def web_request?
    # Consider HTML, CSV, and other web formats as web requests
    # Also include JSON requests that come from web forms (with CSRF tokens)
    request.format.html? ||
    request.format.csv? ||
    request.format.xml? ||
    (request.format.json? && params[:authenticity_token].present?)
  end

  def authenticate_request
    if web_request?
      # For web requests (HTML, CSV, etc.), redirect to login if not authenticated
      unless current_user
        respond_to do |format|
          format.html { redirect_to login_path, alert: "Please sign in to continue" }
          format.csv { redirect_to login_path, alert: "Please sign in to continue" }
          format.xml { redirect_to login_path, alert: "Please sign in to continue" }
          format.any { redirect_to login_path, alert: "Please sign in to continue" }
        end
      end
    else
      # For API requests, use JWT authentication
      authenticate_with_jwt || render_unauthorized
    end
  end

  def authenticate_with_jwt
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    if token && (decoded_token = User.decode_token(token))
      User.find(decoded_token[0]["user_id"])
    end
  rescue ActiveRecord::RecordNotFound, JWT::DecodeError
    nil
  end

  def render_unauthorized
    render json: { error: "Not Authorized" }, status: :unauthorized
  end

  def authorize_role(role)
    unless @current_user && @current_user.send("#{role}?")
      render json: { error: "Forbidden: You must be a #{role} to perform this action" }, status: :forbidden
    end
  end

  def skip_authentication
    skip_before_action :authenticate_request
  end
  
  # Error handlers
  def record_not_found(exception)
    respond_to do |format|
      format.html { render file: 'public/404.html', status: :not_found, layout: false }
      format.json { render json: { error: 'Record not found' }, status: :not_found }
    end
  end
  
  def parameter_missing(exception)
    render json: { error: "Missing parameter: #{exception.param}" }, status: :bad_request
  end
  
  def record_invalid(exception)
    render json: { 
      error: 'Validation failed', 
      details: exception.record.errors.full_messages 
    }, status: :unprocessable_entity
  end
  
  # Request tracking
  def set_request_id
    # Use Rails' built-in request ID
    response.headers['X-Request-ID'] = request.request_id
  end
  
  # Logging helper
  def log_action(action, resource = nil, details = {})
    Rails.logger.info({
      timestamp: Time.current.iso8601,
      request_id: request.request_id,
      user_id: current_user&.id,
      action: action,
      resource: resource,
      details: details,
      ip: request.remote_ip,
      user_agent: request.user_agent
    }.to_json)
  end
end
