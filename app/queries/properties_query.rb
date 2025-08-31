class PropertiesQuery < ApplicationQuery
  def initialize(relation = Property.all)
    super(relation)
  end

  # Search methods
  def search(query)
    return self if query.blank?
    
    search_term = "%#{query}%"
    @relation = @relation.where(
      "title ILIKE :term OR description ILIKE :term OR location ILIKE :term OR address ILIKE :term",
      term: search_term
    )
    self
  end

  # Filter by location with radius (if latitude/longitude are available)
  def near_location(latitude, longitude, radius_km = 10)
    return self unless latitude.present? && longitude.present?
    
    # Using PostgreSQL earthdistance extension
    # You'll need to add these columns and extension to use this
    @relation = @relation.where(
      "earth_distance(ll_to_earth(latitude, longitude), ll_to_earth(?, ?)) <= ?",
      latitude, longitude, radius_km * 1000
    )
    self
  end

  # Filter by price range
  def price_between(min_price, max_price)
    @relation = @relation.where(price: min_price..max_price) if min_price && max_price
    @relation = @relation.where("price >= ?", min_price) if min_price && !max_price
    @relation = @relation.where("price <= ?", max_price) if !min_price && max_price
    self
  end

  # Filter by number of bedrooms
  def with_bedrooms(count)
    return self unless count.present?
    
    if count.to_i >= 4
      @relation = @relation.where("bedrooms >= ?", count)
    else
      @relation = @relation.where(bedrooms: count)
    end
    self
  end

  # Filter by number of bathrooms
  def with_bathrooms(count)
    return self unless count.present?
    
    if count.to_i >= 3
      @relation = @relation.where("bathrooms >= ?", count)
    else
      @relation = @relation.where(bathrooms: count)
    end
    self
  end

  # Filter by property type
  def of_type(property_type)
    return self unless property_type.present?
    
    @relation = @relation.where(property_type: property_type)
    self
  end

  # Filter by status
  def with_status(status)
    return self unless status.present?
    
    @relation = @relation.where(status: status)
    self
  end

  # Filter by amenities (assuming JSONB column)
  def with_amenities(amenities)
    return self unless amenities.present?
    
    amenities = Array(amenities)
    amenities.each do |amenity|
      @relation = @relation.where("amenities ? :amenity", amenity: amenity)
    end
    self
  end

  # Filter by pet-friendly
  def pet_friendly(value = true)
    @relation = @relation.where(pet_friendly: value)
    self
  end

  # Filter by parking availability
  def with_parking(value = true)
    @relation = @relation.where(parking_available: value)
    self
  end

  # Filter by furnished status
  def furnished(value = true)
    @relation = @relation.where(furnished: value)
    self
  end

  # Filter by landlord
  def by_landlord(user_id)
    return self unless user_id.present?
    
    @relation = @relation.where(user_id: user_id)
    self
  end

  # Filter by date range
  def listed_between(start_date, end_date)
    return self unless start_date || end_date
    
    @relation = @relation.where(created_at: start_date..end_date) if start_date && end_date
    @relation = @relation.where("created_at >= ?", start_date) if start_date && !end_date
    @relation = @relation.where("created_at <= ?", end_date) if !start_date && end_date
    self
  end

  # Filter to show only available properties
  def available
    @relation = @relation.where(status: 'available')
    self
  end

  # Filter to show featured properties
  def featured
    @relation = @relation.where(featured: true)
    self
  end

  # Sorting methods
  def newest_first
    @relation = @relation.order(created_at: :desc)
    self
  end

  def oldest_first
    @relation = @relation.order(created_at: :asc)
    self
  end

  def price_low_to_high
    @relation = @relation.order(price: :asc)
    self
  end

  def price_high_to_low
    @relation = @relation.order(price: :desc)
    self
  end

  def most_popular
    @relation = @relation
      .left_joins(:property_favorites)
      .group('properties.id')
      .order('COUNT(property_favorites.id) DESC')
    self
  end

  def most_viewed
    @relation = @relation
      .left_joins(:property_viewings)
      .group('properties.id')
      .order('COUNT(property_viewings.id) DESC')
    self
  end

  # Include associations for performance
  def with_associations
    @relation = @relation.includes(
      :user,
      :property_favorites,
      :property_viewings,
      :property_reviews,
      images_attachments: :blob
    )
    self
  end

  # Complex scope combinations
  def recommended_for_user(user)
    return self unless user.present?
    
    # Get user's viewing history to understand preferences
    viewed_properties = user.property_viewings.pluck(:property_id)
    favorited_properties = user.property_favorites.pluck(:property_id)
    
    # Exclude already viewed/favorited
    @relation = @relation.where.not(id: viewed_properties + favorited_properties)
    
    # Apply user's typical search criteria (this would need user preference tracking)
    # For now, just return available properties in similar price range
    if favorited_properties.any?
      avg_price = Property.where(id: favorited_properties).average(:price)
      price_range = (avg_price * 0.8)..(avg_price * 1.2)
      @relation = @relation.where(price: price_range)
    end
    
    self
  end

  protected

  def default_relation
    Property.all
  end
end