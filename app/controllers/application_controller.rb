class ApplicationController < ActionController::Base
  # Skip CSRF protection for API requests
  protect_from_forgery with: :null_session
  before_action :authenticate_request, unless: :html_request?

  attr_reader :current_user
  helper_method :current_user, :user_signed_in?

  def user_signed_in?
    current_user.present?
  end

  private

  def html_request?
    request.format.html?
  end

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    if token && (decoded_token = User.decode_token(token))
      @current_user = User.find(decoded_token[0]["user_id"])
    else
      render json: { error: "Not Authorized" }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { errors: e.message }, status: :unauthorized
  rescue JWT::DecodeError => e
    render json: { errors: e.message }, status: :unauthorized
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
