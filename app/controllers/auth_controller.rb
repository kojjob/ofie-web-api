class AuthController < ApplicationController
  skip_before_action :authenticate_request, only: [ :register, :login ]

  def register
    user = User.new(user_params)

    if user.save
      token = User.encode_token({ user_id: user.id })
      render json: {
        message: "User created successfully",
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        },
        token: token
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      token = User.encode_token({ user_id: user.id })
      render json: {
        message: "Login successful",
        user: {
          id: user.id,
          email: user.email,
          role: user.role
        },
        token: token
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  # Web form methods
  def login_form
    # Render login form
  end

  def register_form
    # Render registration form
  end

  def logout
    # Handle logout - for web interface
    redirect_to root_path, notice: "Logged out successfully"
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role)
  end
end
