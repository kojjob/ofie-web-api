class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :edit, :update ]
  before_action :ensure_current_user, only: [ :edit, :update ]

  # GET /profile
  def show
    @user = current_user
    @properties_count = current_user.properties.count if current_user.landlord?
    @reviews_count = current_user.property_reviews.count
    @favorites_count = current_user.property_favorites.count
    @recent_activities = get_recent_activities
  end

  # GET /profile/edit
  def edit
    @user = current_user
  end

  # PATCH/PUT /profile
  def update
    @user = current_user

    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to profile_path, notice: "Profile updated successfully." }
        format.json { render json: { message: "Profile updated successfully", user: @user } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # GET /settings
  def settings
    @user = current_user
  end

  # PATCH /settings
  def update_settings
    @user = current_user

    if @user.update(settings_params)
      respond_to do |format|
        format.html { redirect_to settings_path, notice: "Settings updated successfully." }
        format.json { render json: { message: "Settings updated successfully" } }
      end
    else
      respond_to do |format|
        format.html { render :settings, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH /change_password
  def change_password
    @user = current_user

    unless @user.authenticate(params[:current_password])
      respond_to do |format|
        format.html { redirect_to settings_path, alert: "Current password is incorrect." }
        format.json { render json: { error: "Current password is incorrect" }, status: :unprocessable_entity }
      end
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      respond_to do |format|
        format.html { redirect_to settings_path, notice: "Password changed successfully." }
        format.json { render json: { message: "Password changed successfully" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to settings_path, alert: @user.errors.full_messages.join(", ") }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user
    @user = params[:id] ? User.find(params[:id]) : current_user
  end

  def ensure_current_user
    redirect_to root_path, alert: "Access denied." unless @user == current_user
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone, :bio, :avatar)
  end

  def settings_params
    params.require(:user).permit(:email_notifications, :sms_notifications, :marketing_emails, :timezone)
  end

  def get_recent_activities
    activities = []

    # Recent property reviews
    if current_user.property_reviews.any?
      activities += current_user.property_reviews.recent.limit(3).map do |review|
        {
          type: "review",
          description: "Reviewed #{review.property.title}",
          date: review.created_at,
          link: property_review_path(review)
        }
      end
    end

    # Recent property favorites
    if current_user.property_favorites.any?
      activities += current_user.property_favorites.recent.limit(3).includes(:property).map do |favorite|
        {
          type: "favorite",
          description: "Favorited #{favorite.property.title}",
          date: favorite.created_at,
          link: property_path(favorite.property)
        }
      end
    end

    # Recent property viewings
    if current_user.property_viewings.any?
      activities += current_user.property_viewings.recent.limit(3).includes(:property).map do |viewing|
        {
          type: "viewing",
          description: "Scheduled viewing for #{viewing.property.title}",
          date: viewing.created_at,
          link: property_path(viewing.property)
        }
      end
    end

    # Sort by date and limit to 5 most recent
    activities.sort_by { |activity| activity[:date] }.reverse.first(5)
  end
end
