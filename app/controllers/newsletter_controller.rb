class NewsletterController < ApplicationController
  # Skip authentication for newsletter signup
  skip_before_action :authenticate_user!, only: [ :create ]

  def create
    @email = params[:email]
    @marketing_consent = params[:marketing_consent]

    if @email.present? && valid_email?(@email)
      # Here you would typically save to database or send to email service
      # For now, we'll just simulate success

      respond_to do |format|
        format.html do
          flash[:notice] = "Thank you for subscribing to our newsletter! You'll receive updates about new properties and market insights."
          redirect_back(fallback_location: root_path)
        end
        format.json do
          render json: {
            status: "success",
            message: "Successfully subscribed to newsletter"
          }
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:alert] = "Please provide a valid email address."
          redirect_back(fallback_location: root_path)
        end
        format.json do
          render json: {
            status: "error",
            message: "Invalid email address"
          }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def valid_email?(email)
    email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
  end
end
