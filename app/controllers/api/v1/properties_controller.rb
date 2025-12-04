# API V1 Properties Controller with Service Object Integration
module Api
  module V1
    class PropertiesController < ApplicationController
      before_action :authenticate_request, except: [ :index, :show, :search ]
      before_action :set_property, only: [ :show, :update, :destroy ]
      before_action :authorize_owner, only: [ :update, :destroy ]

      # GET /api/v1/properties
      def index
        # Use the PropertiesQuery for complex filtering
        query = PropertiesQuery.new
          .search(params[:q])
          .with_status("available")
          .price_between(params[:min_price], params[:max_price])
          .with_bedrooms(params[:bedrooms])
          .with_bathrooms(params[:bathrooms])
          .of_type(params[:property_type])
          .pet_friendly(params[:pet_friendly])
          .with_parking(params[:parking])
          .with_associations

        # Apply sorting
        query = case params[:sort]
        when "price_asc" then query.price_low_to_high
        when "price_desc" then query.price_high_to_low
        when "newest" then query.newest_first
        when "popular" then query.most_popular
        else query.newest_first
        end

        # Cache the results
        cache_key = [ "properties", params.to_unsafe_h.sort ].flatten.join("-")
        @properties = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
          query.paginate(page: params[:page], per_page: params[:per_page] || 20).call
        end

        render json: {
          properties: @properties,
          total_count: @properties.total_count,
          page: @properties.current_page,
          per_page: @properties.limit_value
        }
      end

      # GET /api/v1/properties/search
      def search
        result = Properties::SearchService.call(
          params: search_params,
          user: current_user
        )

        if result.success?
          render json: {
            properties: result.properties,
            total_count: result.total_count,
            filters_applied: result.filters_applied
          }
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/properties/:id
      def show
        # Cache individual property
        @property = Rails.cache.fetch([ "property", params[:id] ], expires_in: 1.hour) do
          Property.includes(:user, :property_reviews)
                  .with_attached_photos
                  .find(params[:id])
        end

        render json: @property
      end

      # POST /api/v1/properties
      def create
        result = Properties::CreateService.call(
          user: current_user,
          params: property_params
        )

        if result.success?
          render json: result.property, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/properties/:id
      def update
        if @property.update(property_params)
          # Clear cache after update
          Rails.cache.delete([ "property", @property.id ])
          Rails.cache.delete_matched("properties/*")

          render json: @property
        else
          render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/properties/:id
      def destroy
        @property.destroy
        # Clear cache after deletion
        Rails.cache.delete([ "property", @property.id ])
        Rails.cache.delete_matched("properties/*")

        head :no_content
      end

      private

      def set_property
        @property = Property.find(params[:id])
      end

      def authorize_owner
        unless @property.user == current_user
          raise AuthorizationError, "You don't have permission to perform this action"
        end
      end

      def property_params
        params.require(:property).permit(
          :title, :description, :address, :city, :state, :zip_code,
          :price, :bedrooms, :bathrooms, :square_feet, :property_type,
          :pet_friendly, :parking_available, :featured, :status,
          images: []
        )
      end

      def search_params
        params.permit(
          :q, :location, :min_price, :max_price, :bedrooms, :bathrooms,
          :property_type, :pet_friendly, :parking, :sort_by, :page, :per_page,
          amenities: []
        )
      end
    end
  end
end
