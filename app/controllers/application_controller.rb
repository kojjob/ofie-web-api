class ApplicationController < ActionController::Base
  # Skip CSRF protection for API requests
  protect_from_forgery with: :null_session
  before_action :authenticate_request, unless: :web_request?

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
    request.format.html? || request.format.csv? || request.format.xml?
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
end
