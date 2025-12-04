# Intelligent Property Recommendation Engine with ML-like features
class PropertyRecommendationEngine
  include ActiveModel::Model

  attr_reader :user, :base_query

  def initialize(user)
    @user = user
    @base_query = Property.status_active.available
  end

  def recommend(search_criteria = {})
    # Start with base query and apply filters
    filtered_properties = apply_search_filters(@base_query, search_criteria)

    # Apply user preference scoring
    scored_properties = apply_preference_scoring(filtered_properties)

    # Apply collaborative filtering (users with similar preferences)
    collaborative_boost = apply_collaborative_filtering(scored_properties)

    # Apply behavioral scoring (user's past actions)
    behavioral_boost = apply_behavioral_scoring(collaborative_boost)

    # Apply market insights scoring
    market_scored = apply_market_scoring(behavioral_boost)

    # Sort by total score and return recommendations
    market_scored.sort_by { |property| -calculate_total_score(property) }.first(20)
  end

  def get_similar_properties(property, limit = 5)
    similar_properties = Property.status_active.available
                                .where.not(id: property.id)
                                .where(
                                  property_type: property.property_type,
                                  city: property.city
                                )
                                .where(
                                  bedrooms: (property.bedrooms - 1)..(property.bedrooms + 1),
                                  price: (property.price * 0.8)..(property.price * 1.2)
                                )

    # Score by similarity
    scored_similar = similar_properties.map do |similar_property|
      similarity_score = calculate_similarity_score(property, similar_property)
      { property: similar_property, similarity_score: similarity_score }
    end

    scored_similar.sort_by { |item| -item[:similarity_score] }
                  .first(limit)
                  .map { |item| item[:property] }
  end

  def get_trending_properties(limit = 10)
    # Properties with high recent activity
    trending_properties = Property.status_active.available
                                 .joins(:property_viewings)
                                 .where(property_viewings: { created_at: 1.week.ago.. })
                                 .group("properties.id")
                                 .order("COUNT(property_viewings.id) DESC")
                                 .limit(limit)
                                 .to_a

    trending_properties
  end

  def get_personalized_recommendations(limit = 15)
    return get_trending_properties(limit) unless @user.tenant?

    # Get user preferences from past activity
    preferences = get_user_preferences

    # Build recommendation query
    recommendations = @base_query.includes(:property_viewings, :property_reviews)

    # Apply preference filters
    recommendations = apply_preference_filters(recommendations, preferences)

    # Score and rank
    scored_recommendations = score_recommendations(recommendations, preferences)

    scored_recommendations.first(limit)
  end

  private

  def apply_search_filters(query, criteria)
    filtered_query = query

    # Apply basic filters
    filtered_query = filtered_query.where(bedrooms: criteria[:bedroom_count]) if criteria[:bedroom_count]
    filtered_query = filtered_query.where(bathrooms: criteria[:bathroom_count]) if criteria[:bathroom_count]
    filtered_query = filtered_query.where(property_type: criteria[:property_type]) if criteria[:property_type]

    # Price filter
    if criteria[:budget]
      filtered_query = filtered_query.where("price <= ?", criteria[:budget])
    elsif criteria[:price_range]
      filtered_query = filtered_query.where(price: criteria[:price_range][:min]..criteria[:price_range][:max])
    end

    # Location filter
    if criteria[:location]
      location_terms = criteria[:location].split(/[,\s]+/).map(&:strip)
      location_conditions = location_terms.map { |term|
        "city ILIKE ? OR address ILIKE ?"
      }.join(" OR ")
      location_values = location_terms.flat_map { |term| [ "%#{term}%", "%#{term}%" ] }

      filtered_query = filtered_query.where(location_conditions, *location_values)
    end

    # Amenity filters
    if criteria[:amenities]
      Array(criteria[:amenities]).each do |amenity|
        case amenity.downcase
        when "parking"
          filtered_query = filtered_query.where(parking_available: true)
        when "pet", "pets"
          filtered_query = filtered_query.where(pets_allowed: true)
        when "furnished"
          filtered_query = filtered_query.where(furnished: true)
        when "utilities"
          filtered_query = filtered_query.where(utilities_included: true)
        when "laundry"
          filtered_query = filtered_query.where(laundry: true)
        when "gym"
          filtered_query = filtered_query.where(gym: true)
        when "pool"
          filtered_query = filtered_query.where(pool: true)
        when "balcony"
          filtered_query = filtered_query.where(balcony: true)
        end
      end
    end

    filtered_query.to_a
  end

  def apply_preference_scoring(properties)
    user_preferences = get_user_preferences

    properties.map do |property|
      preference_score = calculate_preference_score(property, user_preferences)
      property.define_singleton_method(:preference_score) { preference_score }
      property
    end
  end

  def apply_collaborative_filtering(properties)
    similar_users = find_similar_users

    properties.map do |property|
      collaborative_score = calculate_collaborative_score(property, similar_users)
      property.define_singleton_method(:collaborative_score) { collaborative_score }
      property
    end
  end

  def apply_behavioral_scoring(properties)
    user_behavior = analyze_user_behavior

    properties.map do |property|
      behavioral_score = calculate_behavioral_score(property, user_behavior)
      property.define_singleton_method(:behavioral_score) { behavioral_score }
      property
    end
  end

  def apply_market_scoring(properties)
    properties.map do |property|
      market_score = calculate_market_score(property)
      property.define_singleton_method(:market_score) { market_score }
      property
    end
  end

  def calculate_total_score(property)
    base_score = 50

    # Preference alignment (40% weight)
    preference_score = property.respond_to?(:preference_score) ? property.preference_score : 0

    # Collaborative filtering (20% weight)
    collaborative_score = property.respond_to?(:collaborative_score) ? property.collaborative_score : 0

    # Behavioral alignment (25% weight)
    behavioral_score = property.respond_to?(:behavioral_score) ? property.behavioral_score : 0

    # Market factors (15% weight)
    market_score = property.respond_to?(:market_score) ? property.market_score : 0

    total_score = base_score +
                  (preference_score * 0.4) +
                  (collaborative_score * 0.2) +
                  (behavioral_score * 0.25) +
                  (market_score * 0.15)

    # Apply property quality multipliers
    total_score *= 1.2 if property.average_rating > 4.0
    total_score *= 1.1 if property.photos.attached? && property.photos.count > 3
    total_score *= 0.9 if property.created_at < 6.months.ago && property.property_viewings.where("created_at > ?", 1.month.ago).count < 3

    total_score
  end

  def get_user_preferences
    return {} unless @user.tenant?

    preferences = {}

    # Note: User profile preferences would go here if the User model had those fields
    # For now, we extract preferences from user behavior only

    # Extract from rental applications
    recent_applications = @user.tenant_rental_applications.includes(:property).limit(5)
    if recent_applications.any?
      preferences[:preferred_price_range] = calculate_price_range_from_applications(recent_applications)
      preferences[:preferred_locations] = extract_location_preferences(recent_applications)
      preferences[:preferred_property_types] = extract_property_type_preferences(recent_applications)
    end

    # Extract from property viewings
    recent_viewings = @user.property_viewings.includes(:property).limit(10)
    if recent_viewings.any?
      preferences[:viewing_patterns] = analyze_viewing_patterns(recent_viewings)
    end

    # Extract from favorites
    favorites = @user.favorite_properties
    if favorites.any?
      preferences[:favorite_patterns] = analyze_favorite_patterns(favorites)
    end

    preferences
  end

  def calculate_preference_score(property, preferences)
    score = 0

    # Price preference
    if preferences[:preferred_price_range]
      price_range = preferences[:preferred_price_range]
      if property.price >= price_range[:min] && property.price <= price_range[:max]
        score += 20
      elsif property.price <= price_range[:max] * 1.1 # Within 10% of max
        score += 10
      end
    end

    # Location preference
    if preferences[:preferred_locations]
      if preferences[:preferred_locations].any? { |loc| property.city.downcase.include?(loc.downcase) }
        score += 15
      end
    end

    # Property type preference
    if preferences[:preferred_property_types]
      if preferences[:preferred_property_types].include?(property.property_type)
        score += 10
      end
    end

    # Bedroom preference
    if preferences[:preferred_bedrooms]
      if property.bedrooms == preferences[:preferred_bedrooms]
        score += 10
      elsif (property.bedrooms - preferences[:preferred_bedrooms]).abs == 1
        score += 5
      end
    end

    # Amenity preferences
    if preferences[:preferred_amenities]
      matching_amenities = preferences[:preferred_amenities] & property.amenities_list.map(&:downcase)
      score += matching_amenities.count * 3
    end

    score
  end

  def find_similar_users
    return [] unless @user.tenant?

    # Find users with similar application/viewing patterns
    similar_users = User.tenant
                       .joins(:tenant_rental_applications)
                       .where.not(id: @user.id)
                       .group("users.id")
                       .having("COUNT(rental_applications.id) > 0")
                       .limit(20)

    similar_users.select { |user| calculate_user_similarity(user) > 0.3 }
  end

  def calculate_user_similarity(other_user)
    return 0 unless other_user.tenant?

    # Compare application patterns
    my_applications = @user.tenant_rental_applications.includes(:property)
    their_applications = other_user.tenant_rental_applications.includes(:property)

    return 0 if my_applications.empty? || their_applications.empty?

    # Calculate similarity based on property preferences
    my_cities = my_applications.map { |app| app.property.city }.uniq
    their_cities = their_applications.map { |app| app.property.city }.uniq

    my_types = my_applications.map { |app| app.property.property_type }.uniq
    their_types = their_applications.map { |app| app.property.property_type }.uniq

    city_similarity = (my_cities & their_cities).count.to_f / (my_cities | their_cities).count
    type_similarity = (my_types & their_types).count.to_f / (my_types | their_types).count

    (city_similarity + type_similarity) / 2.0
  end

  def calculate_collaborative_score(property, similar_users)
    return 0 if similar_users.empty?

    # Check how many similar users have interacted with this property
    interactions = 0
    positive_interactions = 0

    similar_users.each do |user|
      # Check applications
      if user.tenant_rental_applications.joins(:property).where(properties: { id: property.id }).exists?
        interactions += 1
        positive_interactions += 1
      end

      # Check favorites
      if user.favorite_properties.where(id: property.id).exists?
        interactions += 1
        positive_interactions += 1
      end

      # Check viewings
      if user.property_viewings.where(property: property).exists?
        interactions += 1
        positive_interactions += 0.5 # Viewings are less strong signal than applications/favorites
      end
    end

    return 0 if interactions == 0

    (positive_interactions / interactions.to_f) * 15 # Max 15 points for collaborative filtering
  end

  def analyze_user_behavior
    return {} unless @user.tenant?

    {
      avg_viewing_time_before_application: calculate_avg_viewing_time,
      preferred_viewing_days: calculate_preferred_viewing_days,
      application_speed: calculate_application_speed,
      price_sensitivity: calculate_price_sensitivity,
      amenity_importance: calculate_amenity_importance
    }
  end

  def calculate_behavioral_score(property, behavior)
    score = 0

    # Price sensitivity scoring
    if behavior[:price_sensitivity]
      if behavior[:price_sensitivity] == :low && property.price > 2000
        score += 5 # User doesn't mind higher prices
      elsif behavior[:price_sensitivity] == :high && property.price < 1500
        score += 5 # User prefers lower prices
      end
    end

    # Amenity importance
    if behavior[:amenity_importance] && behavior[:amenity_importance][:high_importance]
      important_amenities = behavior[:amenity_importance][:high_importance]
      property_amenities = property.amenities_list.map(&:downcase)
      matching = important_amenities & property_amenities
      score += matching.count * 2
    end

    score
  end

  def calculate_market_score(property)
    score = 0

    # Recent activity (viewings, applications)
    recent_viewings = property.property_viewings.where("created_at > ?", 1.week.ago).count
    score += [ recent_viewings * 2, 10 ].min # Max 10 points for popularity

    # Price competitiveness in area
    area_properties = Property.status_active.where(
      city: property.city,
      property_type: property.property_type,
      bedrooms: property.bedrooms
    )

    if area_properties.count > 5
      area_avg_price = area_properties.average(:price)
      if property.price <= area_avg_price * 0.95 # 5% below average
        score += 8 # Good value
      elsif property.price <= area_avg_price * 1.05 # Within 5% of average
        score += 5 # Fair value
      end
    end

    # Property quality indicators
    score += 3 if property.photos.attached? && property.photos.count >= 5
    score += 2 if property.description && property.description.length > 200
    score += 5 if property.average_rating > 4.0

    score
  end

  def calculate_similarity_score(property1, property2)
    score = 0

    # Price similarity (20% weight)
    price_diff = (property1.price - property2.price).abs.to_f / [ property1.price, property2.price ].max
    score += (1 - price_diff) * 20

    # Bedroom similarity (20% weight)
    bedroom_diff = (property1.bedrooms - property2.bedrooms).abs
    score += [ 20 - (bedroom_diff * 10), 0 ].max

    # Bathroom similarity (15% weight)
    bathroom_diff = (property1.bathrooms - property2.bathrooms).abs
    score += [ 15 - (bathroom_diff * 7.5), 0 ].max

    # Location similarity (25% weight)
    score += 25 if property1.city == property2.city

    # Amenity similarity (20% weight)
    amenities1 = property1.amenities_list
    amenities2 = property2.amenities_list

    if amenities1.any? && amenities2.any?
      common_amenities = amenities1 & amenities2
      total_amenities = (amenities1 | amenities2).count
      score += (common_amenities.count.to_f / total_amenities) * 20
    end

    score
  end

  # Helper methods for behavior analysis
  def calculate_avg_viewing_time
    # Placeholder - would calculate from actual data
    2.5 # days
  end

  def calculate_preferred_viewing_days
    # Placeholder - would analyze from viewing data
    [ "saturday", "sunday" ]
  end

  def calculate_application_speed
    # Placeholder - would calculate from viewing to application time
    :moderate
  end

  def calculate_price_sensitivity
    return :unknown unless @user.tenant?

    applications = @user.tenant_rental_applications.includes(:property)
    return :unknown if applications.count < 2

    prices = applications.map { |app| app.property.price }
    price_variance = calculate_variance(prices)

    if price_variance < 10000 # Low variance in price preferences
      :low
    elsif price_variance > 50000 # High variance
      :low
    else
      :moderate
    end
  end

  def calculate_amenity_importance
    return {} unless @user.tenant?

    # Analyze which amenities appear most in user's favorites/applications
    favorites = @user.favorite_properties
    applications = @user.tenant_rental_applications.includes(:property)

    amenity_counts = Hash.new(0)

    favorites.each do |property|
      property.amenities_list.each { |amenity| amenity_counts[amenity.downcase] += 2 }
    end

    applications.each do |application|
      application.property.amenities_list.each { |amenity| amenity_counts[amenity.downcase] += 1 }
    end

    sorted_amenities = amenity_counts.sort_by { |_, count| -count }

    {
      high_importance: sorted_amenities.first(3).map(&:first),
      medium_importance: sorted_amenities[3..5]&.map(&:first) || [],
      low_importance: sorted_amenities[6..-1]&.map(&:first) || []
    }
  end

  def calculate_variance(numbers)
    return 0 if numbers.empty?

    mean = numbers.sum.to_f / numbers.count
    variance = numbers.map { |n| (n - mean) ** 2 }.sum / numbers.count
    variance
  end

  # Additional helper methods for preference extraction
  def calculate_price_range_from_applications(applications)
    prices = applications.map { |app| app.property.price }
    {
      min: prices.min,
      max: prices.max,
      avg: prices.sum / prices.count
    }
  end

  def extract_location_preferences(applications)
    applications.map { |app| app.property.city }.uniq
  end

  def extract_property_type_preferences(applications)
    applications.map { |app| app.property.property_type }.uniq
  end

  def analyze_viewing_patterns(viewings)
    {
      avg_viewings_per_property: viewings.group(:property_id).count.values.sum.to_f / viewings.group(:property_id).count.keys.count,
      preferred_viewing_times: viewings.group_by { |v| v.created_at.hour }.transform_values(&:count)
    }
  end

  def analyze_favorite_patterns(favorites)
    property_types = favorites.map(&:property_type).group_by(&:itself).transform_values(&:count)
    price_ranges = favorites.map(&:price).group_by { |price|
      case price
      when 0..1000 then "budget"
      when 1001..2000 then "moderate"
      when 2001..3000 then "premium"
      else "luxury"
      end
    }.transform_values(&:count)

    {
      preferred_types: property_types,
      preferred_price_ranges: price_ranges
    }
  end

  def apply_preference_filters(query, preferences)
    filtered_query = query

    # Apply budget filter if present
    if preferences[:budget_max]
      filtered_query = filtered_query.where("price <= ?", preferences[:budget_max])
    elsif preferences[:preferred_price_range]
      price_range = preferences[:preferred_price_range]
      filtered_query = filtered_query.where(price: price_range[:min]..price_range[:max])
    end

    # Apply location filter if present
    if preferences[:preferred_locations]&.any?
      filtered_query = filtered_query.where(city: preferences[:preferred_locations])
    end

    # Apply property type filter if present
    if preferences[:preferred_property_types]&.any?
      filtered_query = filtered_query.where(property_type: preferences[:preferred_property_types])
    end

    filtered_query.to_a
  end

  def score_recommendations(properties, preferences)
    properties.map do |property|
      # Calculate comprehensive score
      preference_score = calculate_preference_score(property, preferences)
      property.define_singleton_method(:preference_score) { preference_score }

      # Add other scoring components
      collaborative_score = 0 # Simplified for now
      property.define_singleton_method(:collaborative_score) { collaborative_score }

      behavioral_score = 0 # Simplified for now
      property.define_singleton_method(:behavioral_score) { behavioral_score }

      market_score = calculate_market_score(property)
      property.define_singleton_method(:market_score) { market_score }

      property
    end.sort_by { |property| -calculate_total_score(property) }
  end
end
