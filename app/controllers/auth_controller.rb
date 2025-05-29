class AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [
    :register, :login, :verify_email, :request_password_reset,
    :reset_password, :google_oauth2, :facebook
  ]

  def register
    user = User.new(user_params)

    if user.save
      token = User.encode_token({ user_id: user.id })
      refresh_token = user.generate_refresh_token

      render json: {
        message: "User created successfully. Please check your email to verify your account.",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          email_verified: user.email_verified
        },
        token: token,
        refresh_token: refresh_token
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      unless user.email_verified
        return render json: {
          error: "Please verify your email address before logging in.",
          email_verification_required: true
        }, status: :unauthorized
      end

      token = User.encode_token({ user_id: user.id })
      refresh_token = user.generate_refresh_token

      render json: {
        message: "Login successful",
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          email_verified: user.email_verified
        },
        token: token,
        refresh_token: refresh_token
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
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
      render json: { message: "Email verified successfully" }, status: :ok
    else
      render json: { error: "Invalid or expired verification token" }, status: :unprocessable_entity
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

  def request_password_reset
    user = User.find_by(email: params[:email])

    if user
      user.generate_password_reset_token
      UserMailer.password_reset(user).deliver_now
    end

    # Always return success to prevent email enumeration
    render json: { message: "If an account with that email exists, a password reset link has been sent." }, status: :ok
  end

  def reset_password
    token = params[:token]
    user = User.find_by(password_reset_token: token)

    if user && user.password_reset_token_valid?
      if user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        # Clear reset token
        user.update(password_reset_token: nil, password_reset_sent_at: nil)
        render json: { message: "Password reset successfully" }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: "Invalid or expired reset token" }, status: :unprocessable_entity
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

    redirect_to root_path, notice: "Logged out successfully"
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
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
