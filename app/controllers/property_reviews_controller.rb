class PropertyReviewsController < ApplicationController
  before_action :authenticate_request
  before_action :set_property, only: [ :index, :create ]
  before_action :set_review, only: [ :show, :edit, :update, :destroy, :mark_helpful ]
  before_action :ensure_tenant_for_create, only: [ :create ]
  before_action :ensure_owner_or_admin, only: [ :update, :destroy ]

  # GET /properties/:property_id/reviews
  def index
    @reviews = @property.property_reviews.includes(:user).recent.page(params[:page]).per(10)
    @new_review = PropertyReview.new if user_signed_in? && current_user.tenant? && !current_user.property_reviews.exists?(property: @property)

    respond_to do |format|
      format.html
      format.json { render json: { reviews: @reviews, average_rating: @property.average_rating, total_reviews: @property.reviews_count } }
    end
  end

  # GET /property_reviews/:id
  def show
    @property = @review.property
    @related_reviews = @property.property_reviews.where.not(id: @review.id).verified.recent.limit(3)

    respond_to do |format|
      format.html
      format.json { render json: { review: @review, property: @property, related_reviews: @related_reviews } }
    end
  end

  # POST /properties/:property_id/reviews
  def create
    @review = @property.property_reviews.build(review_params)
    @review.user = current_user

    respond_to do |format|
      if @review.save
        format.html { redirect_to property_reviews_path(@property), notice: "Review was successfully created." }
        format.json { render json: @review, status: :created }
      else
        format.html {
          @reviews = @property.property_reviews.includes(:user).recent.page(params[:page]).per(10)
          render :index, status: :unprocessable_entity
        }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /property_reviews/:id/edit
  def edit
    @property = @review.property
  end

  # PATCH/PUT /property_reviews/:id
  def update
    respond_to do |format|
      if @review.update(review_params)
        format.html { redirect_to @review, notice: "Review was successfully updated." }
        format.json { render json: @review }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @review.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /property_reviews/:id
  def destroy
    property = @review.property
    @review.destroy!

    respond_to do |format|
      format.html { redirect_to property_reviews_path(property), notice: "Review was successfully deleted." }
      format.json { head :no_content }
    end
  end

  # PATCH /property_reviews/:id/mark_helpful
  def mark_helpful
    if current_user != @review.user
      @review.increment_helpful_count!

      respond_to do |format|
        format.html { redirect_back(fallback_location: @review) }
        format.json { render json: { helpful_count: @review.helpful_count } }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: @review, alert: "You cannot mark your own review as helpful.") }
        format.json { render json: { error: "Cannot mark own review as helpful" }, status: :unprocessable_entity }
      end
    end
  end

  # GET /users/:user_id/reviews
  def user_reviews
    @user = User.find(params[:user_id])
    @reviews = @user.property_reviews.includes(:property).recent.page(params[:page]).per(10)
    @review_stats = {
      total_reviews: @user.property_reviews.count,
      verified_reviews: @user.property_reviews.verified.count,
      average_rating: @user.property_reviews.average(:rating)&.round(1) || 0.0,
      total_helpful_votes: @user.property_reviews.sum(:helpful_count)
    }

    respond_to do |format|
      format.html
      format.json { render json: { user: @user, reviews: @reviews, stats: @review_stats } }
    end
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_review
    @review = PropertyReview.find(params[:id])
  end

  def review_params
    params.require(:property_review).permit(:rating, :title, :content)
  end

  def ensure_tenant_for_create
    unless current_user.tenant?
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: "Only tenants can write reviews.") }
        format.json { render json: { error: "Only tenants can write reviews" }, status: :forbidden }
      end
    end
  end

  def ensure_owner_or_admin
    unless current_user == @review.user || current_user.admin?
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: "You can only edit your own reviews.") }
        format.json { render json: { error: "Unauthorized" }, status: :forbidden }
      end
    end
  end
end
