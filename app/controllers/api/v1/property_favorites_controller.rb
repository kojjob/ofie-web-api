class Api::V1::PropertyFavoritesController < ApplicationController
  before_action :authenticate_request
  before_action :set_property, only: [ :create, :destroy ]
  before_action :set_favorite, only: [ :destroy ]

  # GET /api/v1/property_favorites
  def index
    @favorites = current_user.property_favorites.includes(:property)
                            .page(params[:page])
                            .per(params[:per_page] || 20)

    render json: {
      favorites: @favorites.map do |favorite|
        {
          id: favorite.id,
          property: property_summary(favorite.property),
          created_at: favorite.created_at
        }
      end,
      pagination: pagination_meta(@favorites)
    }
  end

  # POST /api/v1/properties/:property_id/favorites
  def create
    @favorite = current_user.property_favorites.build(property: @property)

    if @favorite.save
      render json: {
        message: "Property added to favorites",
        favorite: {
          id: @favorite.id,
          property_id: @property.id,
          created_at: @favorite.created_at
        }
      }, status: :created
    else
      render json: {
        error: "Failed to add to favorites",
        details: @favorite.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/properties/:property_id/favorites
  def destroy
    if @favorite
      @favorite.destroy
      render json: { message: "Property removed from favorites" }
    else
      render json: { error: "Favorite not found" }, status: :not_found
    end
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def set_favorite
    @favorite = current_user.property_favorites.find_by(property: @property)
  end

  def property_summary(property)
    {
      id: property.id,
      title: property.title,
      address: property.address,
      city: property.city,
      state: property.state,
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      property_type: property.property_type,
      availability_status: property.availability_status,
      photos: property.photos.attached? ? property.photos.map { |photo| url_for(photo) } : []
    }
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
