module Properties
  class SearchService < ApplicationService
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100

    def initialize(params:, user: nil)
      @params = params
      @user = user
      @filters = build_filters
    end

    def call
      properties = base_query
      properties = apply_filters(properties)
      properties = apply_sorting(properties)
      properties = apply_pagination(properties)

      success(
        properties: properties,
        total_count: properties.total_count,
        page: current_page,
        per_page: per_page,
        filters_applied: @filters.keys
      )
    rescue StandardError => e
      log_execution("Search failed: #{e.message}", :error)
      failure("Search failed. Please try again.")
    end

    private

    attr_reader :params, :user, :filters

    def base_query
      Property.includes(:user, :property_favorites, images_attachments: :blob)
              .where(status: "available")
    end

    def build_filters
      {}.tap do |f|
        f[:location] = params[:location] if params[:location].present?
        f[:min_price] = params[:min_price].to_f if params[:min_price].present?
        f[:max_price] = params[:max_price].to_f if params[:max_price].present?
        f[:bedrooms] = params[:bedrooms].to_i if params[:bedrooms].present?
        f[:bathrooms] = params[:bathrooms].to_i if params[:bathrooms].present?
        f[:property_type] = params[:property_type] if params[:property_type].present?
        f[:amenities] = params[:amenities].split(",") if params[:amenities].present?
        f[:pet_friendly] = params[:pet_friendly] == "true" if params[:pet_friendly].present?
        f[:parking] = params[:parking] == "true" if params[:parking].present?
      end
    end

    def apply_filters(properties)
      properties = filter_by_location(properties) if filters[:location]
      properties = filter_by_price_range(properties)
      properties = filter_by_bedrooms(properties) if filters[:bedrooms]
      properties = filter_by_bathrooms(properties) if filters[:bathrooms]
      properties = filter_by_property_type(properties) if filters[:property_type]
      properties = filter_by_amenities(properties) if filters[:amenities]
      properties = filter_by_pet_friendly(properties) if filters.key?(:pet_friendly)
      properties = filter_by_parking(properties) if filters.key?(:parking)
      properties
    end

    def filter_by_location(properties)
      # Use PostgreSQL full-text search for better matching
      properties.where("location ILIKE ? OR address ILIKE ?",
                      "%#{filters[:location]}%",
                      "%#{filters[:location]}%")
    end

    def filter_by_price_range(properties)
      properties = properties.where("price >= ?", filters[:min_price]) if filters[:min_price]
      properties = properties.where("price <= ?", filters[:max_price]) if filters[:max_price]
      properties
    end

    def filter_by_bedrooms(properties)
      if filters[:bedrooms] >= 4
        properties.where("bedrooms >= ?", filters[:bedrooms])
      else
        properties.where(bedrooms: filters[:bedrooms])
      end
    end

    def filter_by_bathrooms(properties)
      if filters[:bathrooms] >= 3
        properties.where("bathrooms >= ?", filters[:bathrooms])
      else
        properties.where(bathrooms: filters[:bathrooms])
      end
    end

    def filter_by_property_type(properties)
      properties.where(property_type: filters[:property_type])
    end

    def filter_by_amenities(properties)
      # Assuming amenities are stored as JSONB
      filters[:amenities].each do |amenity|
        properties = properties.where("amenities ? :amenity", amenity: amenity)
      end
      properties
    end

    def filter_by_pet_friendly(properties)
      properties.where(pet_friendly: filters[:pet_friendly])
    end

    def filter_by_parking(properties)
      properties.where(parking_available: filters[:parking])
    end

    def apply_sorting(properties)
      case params[:sort_by]
      when "price_asc"
        properties.order(price: :asc)
      when "price_desc"
        properties.order(price: :desc)
      when "newest"
        properties.order(created_at: :desc)
      when "bedrooms"
        properties.order(bedrooms: :desc)
      when "popular"
        properties.left_joins(:property_favorites)
                 .group("properties.id")
                 .order("COUNT(property_favorites.id) DESC")
      else
        properties.order(created_at: :desc)
      end
    end

    def apply_pagination(properties)
      properties.page(current_page).per(per_page)
    end

    def current_page
      [ params[:page].to_i, 1 ].max
    end

    def per_page
      requested = params[:per_page].to_i
      return DEFAULT_PER_PAGE if requested <= 0
      [ requested, MAX_PER_PAGE ].min
    end
  end
end
