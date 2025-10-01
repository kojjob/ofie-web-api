# Enhanced Property Search Service with AI Integration
class PropertySearchService
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attr_reader :user, :search_params, :context

  def initialize(search_params = {}, user: nil, context: {})
    @search_params = (search_params || {}).with_indifferent_access
    @user = user
    @context = context
  end

  def call
    # Build base query
    query = build_base_query

    # Apply search filters
    query = apply_search_filters(query)

    # Apply user personalization if available
    query = apply_personalization(query) if @user

    # Apply intelligent sorting
    results = apply_intelligent_sorting(query)

    # Post-process results
    enhanced_results = enhance_results(results)

    # Track search for analytics and personalization
    track_search_analytics

    {
      properties: enhanced_results,
      total_count: query.count,
      search_metadata: generate_search_metadata,
      suggestions: generate_search_suggestions,
      filters_applied: get_applied_filters
    }
  end

  private

  def build_base_query
    Property.status_active
            .available
            .includes(:user, :property_favorites, :property_reviews, photos_attachments: :blob)
  end

  def apply_search_filters(query)
    filtered_query = query

    # Location-based filtering
    filtered_query = apply_location_filters(filtered_query)

    # Price filtering
    filtered_query = apply_price_filters(filtered_query)

    # Size filtering (bedrooms, bathrooms, square feet)
    filtered_query = apply_size_filters(filtered_query)

    # Property type filtering
    filtered_query = apply_property_type_filters(filtered_query)

    # Amenity filtering
    filtered_query = apply_amenity_filters(filtered_query)

    # Availability filtering
    filtered_query = apply_availability_filters(filtered_query)

    # Advanced filtering
    filtered_query = apply_advanced_filters(filtered_query)

    filtered_query
  end

  def apply_location_filters(query)
    return query unless location_params.any?

    if search_params[:location].present?
      location_query = search_params[:location].strip

      # Smart location parsing
      location_parts = parse_location_query(location_query)

      query = query.where(
        build_location_conditions(location_parts),
        *build_location_values(location_parts)
      )
    end

    # Specific location filters
    query = query.where(city: search_params[:city]) if search_params[:city].present?
    query = query.where(state: search_params[:state]) if search_params[:state].present?
    query = query.where(zip_code: search_params[:zip_code]) if search_params[:zip_code].present?

    # Radius-based search
    if search_params[:latitude].present? && search_params[:longitude].present? && search_params[:radius].present?
      query = apply_radius_search(query)
    end

    query
  end

  def apply_price_filters(query)
    return query unless price_params.any?

    if search_params[:min_price].present? && search_params[:max_price].present?
      query = query.where(price: search_params[:min_price]..search_params[:max_price])
    elsif search_params[:min_price].present?
      query = query.where("price >= ?", search_params[:min_price])
    elsif search_params[:max_price].present?
      query = query.where("price <= ?", search_params[:max_price])
    end

    # Budget-based filtering
    if search_params[:budget].present?
      query = query.where("price <= ?", search_params[:budget])
    end

    query
  end

  def apply_size_filters(query)
    # Bedroom filtering
    if search_params[:bedrooms].present?
      query = query.where(bedrooms: search_params[:bedrooms])
    elsif search_params[:min_bedrooms].present?
      query = query.where("bedrooms >= ?", search_params[:min_bedrooms])
    end

    # Bathroom filtering
    if search_params[:bathrooms].present?
      query = query.where(bathrooms: search_params[:bathrooms])
    elsif search_params[:min_bathrooms].present?
      query = query.where("bathrooms >= ?", search_params[:min_bathrooms])
    end

    # Square footage filtering
    if search_params[:min_square_feet].present?
      query = query.where("square_feet >= ?", search_params[:min_square_feet])
    end

    if search_params[:max_square_feet].present?
      query = query.where("square_feet <= ?", search_params[:max_square_feet])
    end

    query
  end

  def apply_property_type_filters(query)
    return query unless search_params[:property_type].present?

    property_types = Array(search_params[:property_type])
    query.where(property_type: property_types)
  end

  def apply_amenity_filters(query)
    amenities = extract_amenity_filters
    return query if amenities.empty?

    amenities.each do |amenity|
      case amenity.downcase
      when "parking"
        query = query.where(parking_available: true)
      when "pets", "pet_friendly"
        query = query.where(pets_allowed: true)
      when "furnished"
        query = query.where(furnished: true)
      when "utilities"
        query = query.where(utilities_included: true)
      when "laundry"
        query = query.where(laundry: true)
      when "gym"
        query = query.where(gym: true)
      when "pool"
        query = query.where(pool: true)
      when "balcony"
        query = query.where(balcony: true)
      when "air_conditioning"
        query = query.where(air_conditioning: true)
      when "heating"
        query = query.where(heating: true)
      end
    end

    query
  end

  def apply_availability_filters(query)
    # Move-in date filtering
    if search_params[:move_in_date].present?
      begin
        move_in_date = Date.parse(search_params[:move_in_date])
        # Properties available by the requested move-in date
        query = query.where("available_date <= ? OR available_date IS NULL", move_in_date)
      rescue Date::Error, ArgumentError
        # Invalid date format - skip filtering
        Rails.logger.warn("Invalid move_in_date format: #{search_params[:move_in_date]}")
      end
    end

    # Lease duration filtering
    if search_params[:lease_duration].present?
      # Filter based on minimum lease terms
      query = query.where("min_lease_term <= ? OR min_lease_term IS NULL", search_params[:lease_duration])
    end

    query
  end

  def apply_advanced_filters(query)
    # Recently updated properties
    if search_params[:recently_updated] == "true"
      query = query.where("updated_at > ?", 7.days.ago)
    end

    # Properties with virtual tours
    if search_params[:virtual_tour] == "true"
      query = query.where(virtual_tour_available: true)
    end

    # Properties with high ratings
    if search_params[:high_rated] == "true"
      query = query.joins(:property_reviews)
                   .group("properties.id")
                   .having("AVG(property_reviews.rating) >= ?", 4.0)
    end

    # Properties with photos
    if search_params[:has_photos] == "true"
      query = query.joins(:photos_attachments)
    end

    query
  end

  def apply_personalization(query)
    return query unless @user&.tenant?

    # Apply user preferences - ensure we handle both string and symbol keys
    user_preferences = (@user.preferences || {}).with_indifferent_access

    # Preferred property types
    if user_preferences[:preferred_property_types]&.any?
      preferred_types = user_preferences[:preferred_property_types]
      query = boost_matching_properties(query, property_type: preferred_types)
    end

    # Budget preferences
    if user_preferences[:budget_max]
      max_budget = user_preferences[:budget_max].to_f
      query = query.where("price <= ?", max_budget * 1.1) # Allow 10% over budget
    end

    # Location preferences
    if user_preferences[:preferred_locations]&.any?
      preferred_locations = user_preferences[:preferred_locations]
      query = boost_matching_properties(query, city: preferred_locations)
    end

    # Amenity preferences
    if user_preferences[:preferred_amenities]&.any?
      query = apply_preferred_amenities(query, user_preferences[:preferred_amenities])
    end

    # Exclude previously viewed/rejected properties if specified
    if search_params[:exclude_viewed] == "true"
      viewed_property_ids = @user.property_viewings.pluck(:property_id)
      query = query.where.not(id: viewed_property_ids) if viewed_property_ids.any?
    end

    query
  end

  def apply_intelligent_sorting(query)
    sort_option = search_params[:sort] || determine_intelligent_sort

    case sort_option
    when "price_asc"
      query.order(:price)
    when "price_desc"
      query.order(price: :desc)
    when "newest"
      query.order(created_at: :desc)
    when "rating"
      query.left_joins(:property_reviews)
           .group("properties.id")
           .order("AVG(property_reviews.rating) DESC NULLS LAST")
    when "popularity"
      query.order(views_count: :desc, favorites_count: :desc)
    when "relevance"
      apply_relevance_sorting(query)
    when "recommended"
      apply_recommendation_sorting(query)
    else
      apply_smart_default_sorting(query)
    end
  end

  def enhance_results(properties)
    properties.map do |property|
      # Calculate relevance score for each property
      relevance_score = calculate_property_relevance(property)

      # Add computed fields
      property.define_singleton_method(:relevance_score) { relevance_score }
      property.define_singleton_method(:match_reasons) { calculate_match_reasons(property) }
      property.define_singleton_method(:recommendation_tags) { generate_recommendation_tags(property) }

      property
    end
  end

  def calculate_property_relevance(property)
    score = 50 # Base score

    # Location relevance
    score += calculate_location_relevance(property)

    # Price relevance
    score += calculate_price_relevance(property)

    # Feature matching
    score += calculate_feature_relevance(property)

    # User preference alignment
    score += calculate_preference_alignment(property) if @user

    # Property quality indicators
    score += calculate_quality_score(property)

    [ score, 100 ].min
  end

  def generate_search_metadata
    {
      search_id: SecureRandom.uuid,
      timestamp: Time.current,
      filters_count: count_applied_filters,
      personalized: @user.present?,
      search_context: @context,
      estimated_results: estimate_total_results,
      search_suggestions: generate_search_improvement_suggestions
    }
  end

  def generate_search_suggestions
    suggestions = []

    # Suggest broadening search if few results
    if estimate_total_results < 5
      suggestions << generate_broadening_suggestions
    end

    # Suggest refinements if too many results
    if estimate_total_results > 50
      suggestions << generate_refinement_suggestions
    end

    # Suggest alternative searches
    suggestions << generate_alternative_suggestions

    suggestions.flatten.compact.uniq
  end

  def track_search_analytics
    return unless @user

    # SearchAnalytics model doesn't exist yet - skip for now
    # SearchAnalytics.create!(
    #   user: @user,
    #   search_params: @search_params,
    #   results_count: estimate_total_results,
    #   personalized: @user.present?,
    #   search_context: @context,
    #   timestamp: Time.current
    # )
  end

  # Sorting helper methods
  def apply_relevance_sorting(query)
    # Sort by relevance score (calculated based on search criteria match)
    query.order(updated_at: :desc)
  end

  def apply_recommendation_sorting(query)
    # Sort by personalized recommendations
    if @user
      query.order(updated_at: :desc)
    else
      apply_smart_default_sorting(query)
    end
  end

  def apply_smart_default_sorting(query)
    # Intelligent default sorting based on search context
    if search_params[:location].present?
      query.order(updated_at: :desc)
    else
      query.order(price: :asc)
    end
  end

  # Helper methods
  def location_params
    search_params.slice(:location, :city, :state, :zip_code, :latitude, :longitude, :radius)
               .reject { |_, v| v.blank? }
  end

  def price_params
    search_params.slice(:min_price, :max_price, :budget)
               .reject { |_, v| v.blank? }
  end

  def parse_location_query(location_query)
    # Smart parsing of location strings like "Seattle, WA" or "Downtown Seattle"
    parts = location_query.split(",").map(&:strip)

    if parts.length == 2
      { city: parts[0], state: parts[1] }
    elsif parts.length == 1
      { query: parts[0] }
    else
      { query: location_query }
    end
  end

  def build_location_conditions(location_parts)
    conditions = []

    if location_parts[:city] && location_parts[:state]
      conditions << "city ILIKE ? AND state ILIKE ?"
    elsif location_parts[:query]
      # neighborhood field doesn't exist in schema
      conditions << "(city ILIKE ? OR address ILIKE ?)"
    end

    conditions.join(" OR ")
  end

  def build_location_values(location_parts)
    values = []

    if location_parts[:city] && location_parts[:state]
      values << "%#{location_parts[:city]}%"
      values << "%#{location_parts[:state]}%"
    elsif location_parts[:query]
      query_pattern = "%#{location_parts[:query]}%"
      # Only two values needed (city and address, no neighborhood)
      values << query_pattern << query_pattern
    end

    values
  end

  def extract_amenity_filters
    amenities = []

    # Direct amenity parameters
    search_params.each do |key, value|
      if key.to_s.end_with?("_amenity") && value.present?
        amenities << key.to_s.gsub("_amenity", "")
      end
    end

    # Amenities array parameter
    if search_params[:amenities].present?
      amenities.concat(Array(search_params[:amenities]))
    end

    amenities.uniq
  end

  def determine_intelligent_sort
    # Determine best sorting based on search context and user behavior
    return "recommended" if @user && has_user_preferences?
    return "relevance" if has_specific_search_criteria?
    return "newest" if search_params[:recently_updated] == "true"

    "relevance"
  end

  def has_user_preferences?
    @user&.preferences&.any?
  end

  def has_specific_search_criteria?
    search_params.except(:sort, :page, :per_page).any? { |_, v| v.present? }
  end

  def estimate_total_results
    # Quick estimation without executing the full query
    @estimated_count ||= begin
      base_query = Property.status_active.available

      # Apply major filters for estimation
      if search_params[:city].present?
        base_query = base_query.where(city: search_params[:city])
      end

      if search_params[:min_price].present? || search_params[:max_price].present?
        price_range = [ search_params[:min_price] || 0, search_params[:max_price] || Float::INFINITY ]
        base_query = base_query.where(price: price_range[0]..price_range[1])
      end

      base_query.count
    end
  end

  def count_applied_filters
    search_params.except(:sort, :page, :per_page).count { |_, v| v.present? }
  end

  def get_applied_filters
    applied = {}

    search_params.each do |key, value|
      next if value.blank?
      next if %w[sort page per_page].include?(key.to_s)

      applied[key.to_sym] = value
    end

    applied
  end

  # Relevance calculation helper methods
  def calculate_location_relevance(property)
    score = 0

    if search_params[:city].present? && property.city == search_params[:city]
      score += 10
    end

    score
  end

  def calculate_price_relevance(property)
    score = 0

    if search_params[:budget].present?
      budget = search_params[:budget].to_f
      if property.price <= budget
        score += 10
      end
    end

    score
  end

  def calculate_feature_relevance(property)
    score = 0

    # Amenity matching
    if search_params[:amenities].present?
      amenities = search_params[:amenities].is_a?(Array) ? search_params[:amenities] : [search_params[:amenities]]
      amenities.each do |amenity|
        score += 2 if property.send(amenity) rescue 0
      end
    end

    score
  end

  def calculate_preference_alignment(property)
    # User preference alignment - placeholder for future enhancement
    0
  end

  def calculate_quality_score(property)
    score = 0

    # Views count indicates popularity
    score += (property.views_count || 0) / 10

    score
  end

  def calculate_match_reasons(property)
    reasons = []

    if search_params[:city].present? && property.city == search_params[:city]
      reasons << "Located in #{property.city}"
    end

    if search_params[:budget].present? && property.price <= search_params[:budget].to_f
      reasons << "Within budget"
    end

    reasons
  end

  # Search suggestion helper methods
  def generate_search_improvement_suggestions
    []  # Placeholder - can be enhanced with ML suggestions
  end

  def generate_broadening_suggestions
    suggestions = []

    if search_params[:min_price].present?
      suggestions << "Try lowering minimum price"
    end

    if search_params[:bedrooms].present?
      suggestions << "Try fewer bedrooms"
    end

    suggestions
  end

  def generate_refinement_suggestions
    suggestions = []

    if search_params[:max_price].blank?
      suggestions << "Try setting a maximum price"
    end

    if search_params[:property_type].blank?
      suggestions << "Try filtering by property type"
    end

    suggestions
  end

  def generate_alternative_suggestions
    []  # Placeholder - can suggest related searches
  end

  def boost_matching_properties(query, conditions)
    # For now, just return the query unchanged
    # In a full implementation, this could reorder results to boost matching properties
    # or add scoring columns for relevance ranking
    query
  end

  def apply_preferred_amenities(query, preferred_amenities)
    # Apply amenity filters based on user preferences
    preferred_amenities.each do |amenity|
      case amenity.downcase
      when "parking"
        query = query.where(parking_available: true)
      when "pets", "pet_friendly"
        query = query.where(pets_allowed: true)
      when "furnished"
        query = query.where(furnished: true)
      when "utilities"
        query = query.where(utilities_included: true)
      when "laundry"
        query = query.where(laundry: true)
      when "gym"
        query = query.where(gym: true)
      when "pool"
        query = query.where(pool: true)
      when "balcony"
        query = query.where(balcony: true)
      when "air_conditioning"
        query = query.where(air_conditioning: true)
      when "heating"
        query = query.where(heating: true)
      end
    end
    query
  end

  def generate_recommendation_tags(property)
    []  # Placeholder - can add recommendation reasons
  end
end
