class Api::V1::PropertyReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property, only: [ :index, :create ]
  before_action :set_review, only: [ :show, :update, :destroy, :mark_helpful ]

  # GET /api/v1/properties/:property_id/reviews
  def index
    @reviews = @property.property_reviews.includes(:user)

    # Filter by verification status if provided
    @reviews = @reviews.verified if params[:verified] == "true"
    @reviews = @reviews.unverified if params[:verified] == "false"

    # Filter by rating if provided
    @reviews = @reviews.by_rating(params[:rating]) if params[:rating].present?

    # Sort options
    case params[:sort]
    when "helpful"
      @reviews = @reviews.most_helpful
    when "rating_high"
      @reviews = @reviews.order(rating: :desc)
    when "rating_low"
      @reviews = @reviews.order(rating: :asc)
    else
      @reviews = @reviews.recent
    end

    @reviews = @reviews.page(params[:page]).per(params[:per_page] || 10)

    render json: {
      reviews: @reviews.map { |review| review_json(review) },
      pagination: pagination_meta(@reviews),
      summary: {
        total_reviews: @property.reviews_count,
        average_rating: @property.average_rating,
        rating_distribution: @property.property_reviews.rating_distribution
      }
    }
  end

  # GET /api/v1/property_reviews/:id
  def show
    render json: { review: review_json(@review) }
  end

  # POST /api/v1/properties/:property_id/reviews
  def create
    @review = current_user.property_reviews.build(review_params.merge(property: @property))

    if @review.save
      render json: {
        message: "Review created successfully",
        review: review_json(@review)
      }, status: :created
    else
      render json: {
        error: "Failed to create review",
        details: @review.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/property_reviews/:id
  def update
    # Only allow users to update their own reviews
    unless @review.user == current_user
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    if @review.update(review_params)
      render json: {
        message: "Review updated successfully",
        review: review_json(@review)
      }
    else
      render json: {
        error: "Failed to update review",
        details: @review.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/property_reviews/:id
  def destroy
    # Only allow users to delete their own reviews or property owners
    unless @review.user == current_user || @review.property.user == current_user
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    @review.destroy
    render json: { message: "Review deleted successfully" }
  end

  # POST /api/v1/property_reviews/:id/helpful
  def mark_helpful
    @review.increment_helpful_count!
    render json: {
      message: "Review marked as helpful",
      helpful_count: @review.helpful_count
    }
  end

  # GET /api/v1/users/:user_id/reviews (user's reviews)
  def user_reviews
    user = User.find(params[:user_id])
    @reviews = user.property_reviews.includes(:property).recent
                   .page(params[:page]).per(params[:per_page] || 10)

    render json: {
      reviews: @reviews.map { |review| review_json(review, include_property: true) },
      pagination: pagination_meta(@reviews)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def set_review
    @review = PropertyReview.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Review not found" }, status: :not_found
  end

  def review_params
    params.require(:review).permit(:rating, :title, :content)
  end

  def review_json(review, include_property: false)
    result = {
      id: review.id,
      rating: review.rating,
      title: review.title,
      content: review.content,
      verified: review.verified,
      helpful_count: review.helpful_count,
      created_at: review.created_at,
      updated_at: review.updated_at,
      user: {
        id: review.user.id,
        email: review.user.email.split("@").first + "@***" # Partially hide email for privacy
      }
    }

    if include_property
      result[:property] = {
        id: review.property.id,
        title: review.property.title,
        address: review.property.address,
        city: review.property.city,
        state: review.property.state
      }
    end

    result
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
