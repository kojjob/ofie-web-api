class AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [
    :register, :login, :verify_email, :request_password_reset, :forgot_password,
    :reset_password, :google_oauth2, :facebook, :login_form, :register_form
  ]

  def register
    user = User.new(user_params)

    if user.save
      respond_to do |format|
        format.html do
          session[:user_id] = user.id
          redirect_to root_path, notice: "Welcome to Ofie, #{user.name}!"
        end
        format.json do
          token = User.encode_token({ user_id: user.id })
          refresh_token = user.generate_refresh_token

          render json: {
            message: "User created successfully.",
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role,
              email_verified: user.email_verified
            },
            token: token,
            refresh_token: refresh_token
          }, status: :created
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to register_path, alert: user.errors.full_messages.join(", ") }
        format.json { render json: { errors: user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])

      # For HTML requests, use session-based authentication
      if request.format.html?
        session[:user_id] = user.id
        redirect_to root_path, notice: "Welcome back, #{user.name}!"
      else
        # For API requests, use JWT tokens
        token = User.encode_token({ user_id: user.id })
        refresh_token = user.generate_refresh_token

        render json: {
          message: "Login successful",
          user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            email_verified: user.email_verified
          },
          token: token,
          refresh_token: refresh_token
        }, status: :ok
      end
    else
      error_message = "Invalid email or password"

      respond_to do |format|
        format.json { render json: { error: error_message }, status: :unauthorized }
        format.html { redirect_to login_path, alert: error_message }
      end
    end
  end

  def refresh_token
    refresh_token = params[:refresh_token]
    user = User.find_by(refresh_token: refresh_token)

    if user && user.refresh_token_valid?
      new_token = User.encode_token({ user_id: user.id })
      new_refresh_token = user.generate_refresh_token

      render json: {
        token: new_token,
        refresh_token: new_refresh_token
      }, status: :ok
    else
      render json: { error: "Invalid or expired refresh token" }, status: :unauthorized
    end
  end

  def verify_email
    token = params[:token]
    user = User.find_by(email_verification_token: token)

    if user && user.email_verification_token_valid?
      user.verify_email!

      respond_to do |format|
        format.html { redirect_to login_path, notice: "Email verified successfully! You can now log in." }
        format.json { render json: { message: "Email verified successfully" }, status: :ok }
      end
    else
      error_message = "Invalid or expired verification token"

      respond_to do |format|
        format.html { redirect_to login_path, alert: error_message }
        format.json { render json: { error: error_message }, status: :unprocessable_entity }
      end
    end
  end

  def resend_verification
    user = User.find_by(email: params[:email])

    if user && !user.email_verified
      user.generate_email_verification_token
      user.save!
      UserMailer.email_verification(user).deliver_now
      render json: { message: "Verification email sent" }, status: :ok
    else
      render json: { error: "User not found or already verified" }, status: :unprocessable_entity
    end
  end

  def forgot_password
    if request.post?
      user = User.find_by(email: params[:email])
      if user
        user.generate_password_reset_token!
        UserMailer.password_reset(user).deliver_now

        respond_to do |format|
          format.html { redirect_to login_path, notice: "Password reset email sent. Please check your inbox." }
          format.json { render json: { message: "Password reset email sent" }, status: :ok }
        end
      else
        respond_to do |format|
          format.html { redirect_to forgot_password_path, alert: "Email not found." }
          format.json { render json: { error: "Email not found" }, status: :not_found }
        end
      end
    else
      # GET request - show the form
      render "forgot_password"
    end
  end

  def request_password_reset
    user = User.find_by(email: params[:email])

    if user
      user.generate_password_reset_token!
      UserMailer.password_reset(user).deliver_now
    end

    # Always return success to prevent email enumeration
    render json: { message: "If an account with that email exists, a password reset link has been sent." }, status: :ok
  end

  def reset_password
    @token = params[:token]

    # Debug logging
    Rails.logger.info "=== PASSWORD RESET DEBUG ==="
    Rails.logger.info "Token received: #{@token.inspect}"
    Rails.logger.info "Token length: #{@token&.length}"

    user = User.find_by(password_reset_token: @token)
    Rails.logger.info "User found: #{user.present?}"

    if user
      Rails.logger.info "User email: #{user.email}"
      Rails.logger.info "Token in DB: #{user.password_reset_token.inspect}"
      Rails.logger.info "Token sent at: #{user.password_reset_sent_at}"
      Rails.logger.info "Token valid?: #{user.password_reset_token_valid?}"
      Rails.logger.info "Time now: #{Time.current}"
      Rails.logger.info "2 hours ago: #{2.hours.ago}"
    end
    Rails.logger.info "=== END DEBUG ==="

    if request.get?
      # GET request - show the form
      if user && user.password_reset_token_valid?
        render "reset_password"
      else
        redirect_to login_path, alert: "Invalid or expired password reset token."
      end
    else
      # POST/PATCH request - process the form
      if user && user.password_reset_token_valid?
        if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
          user.clear_password_reset_token!

          respond_to do |format|
            format.html { redirect_to login_path, notice: "Password reset successfully. You can now log in with your new password." }
            format.json { render json: { message: "Password reset successfully" }, status: :ok }
          end
        else
          respond_to do |format|
            format.html { render "reset_password", alert: user.errors.full_messages.join(", ") }
            format.json { render json: { errors: user.errors.full_messages }, status: :unprocessable_entity }
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to login_path, alert: "Invalid or expired token." }
          format.json { render json: { error: "Invalid or expired token" }, status: :unprocessable_entity }
        end
      end
    end
  end

  # OAuth callbacks
  def google_oauth2
    handle_oauth_callback
  end

  def facebook
    handle_oauth_callback
  end

  # Web form methods
  def login_form
    # Render login form
  end

  def register_form
    # Render registration form
  end

  def logout
    if current_user
      # Clear refresh token
      current_user.update(refresh_token: nil, refresh_token_expires_at: nil)
    end

    respond_to do |format|
      format.html do
        session[:user_id] = nil
        redirect_to root_path, notice: "Logged out successfully"
      end
      format.json do
        render json: { message: "Logged out successfully" }, status: :ok
      end
    end
  end

  private

  def user_params
    # Handle both nested user params and flat params from forms
    # Note: :role is NOT permitted directly to prevent privilege escalation
    # Only :user_type is allowed and mapped to safe roles (tenant/landlord)
    if params[:user].present?
      permitted = params.require(:user).permit(:name, :email, :password, :password_confirmation, :user_type)
      map_user_type_to_role(permitted)
    else
      # Handle flat params from HTML forms
      permitted_params = params.permit(:name, :email, :password, :password_confirmation, :user_type)
      map_user_type_to_role(permitted_params)
    end
  end

  def map_user_type_to_role(permitted_params)
    if permitted_params[:user_type].present?
      # Only allow safe user-selectable roles
      user_type = permitted_params.delete(:user_type)
      permitted_params[:role] = user_type if %w[tenant landlord].include?(user_type)
    end
    permitted_params
  end

  def handle_oauth_callback
    auth_hash = request.env["omniauth.auth"]

    begin
      user = User.from_oauth(auth_hash)
      token = User.encode_token({ user_id: user.id })
      refresh_token = user.generate_refresh_token

      render json: {
        message: "OAuth login successful",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          email_verified: user.email_verified,
          provider: user.provider
        },
        token: token,
        refresh_token: refresh_token
      }, status: :ok
    rescue => e
      render json: { error: "OAuth authentication failed: #{e.message}" }, status: :unprocessable_entity
    end
  end
end
