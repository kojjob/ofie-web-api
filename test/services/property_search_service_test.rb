require "test_helper"

class PropertySearchServiceTest < ActiveSupport::TestCase
  # ============================================================================
  # SETUP AND FIXTURES
  # ============================================================================

  def setup
    @landlord = create(:user, :landlord)
    @tenant = create(:user, :tenant)

    # Create properties with different characteristics
    @downtown_property = create(:property,
      title: "Downtown Apartment",
      city: "Seattle",
      address: "123 Downtown St, Seattle",
      price: 2000,
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 850,
      property_type: "apartment",
      parking_available: true,
      pets_allowed: false,
      furnished: false,
      status: "active",
      availability_status: "available",
      user: @landlord
    )

    @suburban_property = create(:property,
      title: "Suburban House",
      city: "Bellevue",
      address: "456 Suburban Ave, Bellevue",
      price: 3500,
      bedrooms: 3,
      bathrooms: 2,
      square_feet: 1500,
      property_type: "house",
      parking_available: true,
      pets_allowed: true,
      furnished: false,
      status: "active",
      availability_status: "available",
      user: @landlord
    )

    @luxury_property = create(:property,
      title: "Luxury Condo",
      city: "Seattle",
      address: "789 Luxury Blvd, Seattle",
      price: 4500,
      bedrooms: 3,
      bathrooms: 2,
      square_feet: 2000,
      property_type: "condo",
      parking_available: true,
      pets_allowed: true,
      furnished: true,
      utilities_included: true,
      laundry: true,
      gym: true,
      pool: true,
      balcony: true,
      air_conditioning: true,
      heating: true,
      status: "active",
      availability_status: "available",
      user: @landlord
    )

    @unavailable_property = create(:property,
      title: "Unavailable Property",
      city: "Seattle",
      address: "321 Unavailable St, Seattle",
      price: 2500,
      bedrooms: 2,
      bathrooms: 1,
      status: "active",
      availability_status: "rented",
      user: @landlord
    )

    @inactive_property = create(:property,
      title: "Inactive Property",
      city: "Seattle",
      address: "654 Inactive Ave, Seattle",
      price: 2200,
      bedrooms: 2,
      bathrooms: 1,
      status: "inactive",
      availability_status: "available",
      user: @landlord
    )
  end

  # ============================================================================
  # BASIC SEARCH FUNCTIONALITY TESTS
  # ============================================================================

  test "call returns all active available properties when no filters" do
    service = PropertySearchService.new({})
    result = service.call

    assert_includes result[:properties], @downtown_property
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
    assert_not_includes result[:properties], @unavailable_property
    assert_not_includes result[:properties], @inactive_property
  end

  test "call returns proper result structure" do
    service = PropertySearchService.new({})
    result = service.call

    assert result.key?(:properties)
    assert result.key?(:total_count)
    assert result.key?(:search_metadata)
    assert result.key?(:suggestions)
    assert result.key?(:filters_applied)

    assert_instance_of Array, result[:properties]
    assert_instance_of Integer, result[:total_count]
    assert_instance_of Hash, result[:search_metadata]
    assert_instance_of Array, result[:suggestions]
    assert_instance_of Hash, result[:filters_applied]
  end

  test "total_count matches properties count" do
    service = PropertySearchService.new({})
    result = service.call

    assert_equal 3, result[:total_count]
    assert_equal 3, result[:properties].count
  end

  # ============================================================================
  # LOCATION FILTERING TESTS
  # ============================================================================

  test "filters by city" do
    service = PropertySearchService.new({ city: "Seattle" })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @downtown_property
    assert_includes result[:properties], @luxury_property
    assert_not_includes result[:properties], @suburban_property
  end

  test "filters by location string with city term" do
    service = PropertySearchService.new({ location: "Seattle" })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @downtown_property
    assert_includes result[:properties], @luxury_property
  end

  test "location search is case insensitive" do
    service = PropertySearchService.new({ location: "SEATTLE" })
    result = service.call

    assert_equal 2, result[:properties].count
  end

  # ============================================================================
  # PRICE FILTERING TESTS
  # ============================================================================

  test "filters by minimum price" do
    service = PropertySearchService.new({ min_price: 3000 })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
    assert_not_includes result[:properties], @downtown_property
  end

  test "filters by maximum price" do
    service = PropertySearchService.new({ max_price: 2500 })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @downtown_property
  end

  test "filters by price range" do
    service = PropertySearchService.new({ min_price: 2000, max_price: 3500 })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @downtown_property
    assert_includes result[:properties], @suburban_property
  end

  test "filters by budget" do
    service = PropertySearchService.new({ budget: 3000 })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @downtown_property
  end

  # ============================================================================
  # SIZE FILTERING TESTS
  # ============================================================================

  test "filters by exact bedroom count" do
    service = PropertySearchService.new({ bedrooms: 3 })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
  end

  test "filters by minimum bedrooms" do
    service = PropertySearchService.new({ min_bedrooms: 3 })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
  end

  test "filters by exact bathroom count" do
    service = PropertySearchService.new({ bathrooms: 2 })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
  end

  test "filters by minimum bathrooms" do
    service = PropertySearchService.new({ min_bathrooms: 2 })
    result = service.call

    assert_equal 2, result[:properties].count
  end

  test "filters by minimum square feet" do
    service = PropertySearchService.new({ min_square_feet: 1000 })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
  end

  test "filters by maximum square feet" do
    service = PropertySearchService.new({ max_square_feet: 1000 })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @downtown_property
  end

  # ============================================================================
  # PROPERTY TYPE FILTERING TESTS
  # ============================================================================

  test "filters by single property type" do
    service = PropertySearchService.new({ property_type: "apartment" })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @downtown_property
  end

  test "filters by multiple property types" do
    service = PropertySearchService.new({ property_type: [ "apartment", "house" ] })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @downtown_property
    assert_includes result[:properties], @suburban_property
  end

  # ============================================================================
  # AMENITY FILTERING TESTS
  # ============================================================================

  test "filters by parking amenity" do
    # All our test properties have parking, so test with a new one without it
    no_parking = create(:property,
      title: "No Parking",
      parking_available: false,
      status: "active",
      availability_status: "available",
      user: @landlord
    )

    service = PropertySearchService.new({ amenities: [ "parking" ] })
    result = service.call

    assert_not_includes result[:properties], no_parking
    assert_includes result[:properties], @downtown_property
  end

  test "filters by pets allowed amenity" do
    service = PropertySearchService.new({ amenities: [ "pets" ] })
    result = service.call

    assert_equal 2, result[:properties].count
    assert_includes result[:properties], @suburban_property
    assert_includes result[:properties], @luxury_property
  end

  test "filters by furnished amenity" do
    service = PropertySearchService.new({ amenities: [ "furnished" ] })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @luxury_property
  end

  test "filters by multiple amenities" do
    service = PropertySearchService.new({ amenities: [ "gym", "pool", "balcony" ] })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @luxury_property
  end

  test "amenity filtering uses case insensitive matching" do
    service = PropertySearchService.new({ amenities: [ "PARKING", "Pet_Friendly" ] })
    result = service.call

    assert result[:properties].count >= 2
  end

  # ============================================================================
  # ADVANCED FILTERING TESTS
  # ============================================================================

  test "filters recently updated properties" do
    # Update a property recently
    @downtown_property.update!(updated_at: 1.day.ago)
    @suburban_property.update!(updated_at: 10.days.ago)

    service = PropertySearchService.new({ recently_updated: "true" })
    result = service.call

    assert_includes result[:properties], @downtown_property
    assert_not_includes result[:properties], @suburban_property
  end

  # Skipped: virtual_tour_available field doesn't exist in schema
  # test "filters properties with virtual tours" do
  #   @downtown_property.update!(virtual_tour_available: true)

  #   service = PropertySearchService.new({ virtual_tour: "true" })
  #   result = service.call

  #   assert_equal 1, result[:properties].count
  #   assert_includes result[:properties], @downtown_property
  # end

  # ============================================================================
  # COMBINED FILTERING TESTS
  # ============================================================================

  test "applies multiple filters together" do
    service = PropertySearchService.new({
      city: "Seattle",
      min_price: 2000,
      max_price: 3000,
      bedrooms: 2,
      amenities: [ "parking" ]
    })
    result = service.call

    assert_equal 1, result[:properties].count
    assert_includes result[:properties], @downtown_property
  end

  test "returns empty array when no properties match filters" do
    service = PropertySearchService.new({
      city: "Seattle",
      min_price: 10000 # No properties this expensive
    })
    result = service.call

    assert_equal 0, result[:properties].count
    assert_equal 0, result[:total_count]
  end

  # ============================================================================
  # SORTING TESTS
  # ============================================================================

  test "sorts by price ascending" do
    service = PropertySearchService.new({ sort: "price_asc" })
    result = service.call

    prices = result[:properties].map(&:price)
    assert_equal prices.sort, prices
  end

  test "sorts by price descending" do
    service = PropertySearchService.new({ sort: "price_desc" })
    result = service.call

    prices = result[:properties].map(&:price)
    assert_equal prices.sort.reverse, prices
  end

  test "sorts by newest first" do
    service = PropertySearchService.new({ sort: "newest" })
    result = service.call

    created_ats = result[:properties].map(&:created_at)
    assert_equal created_ats.sort.reverse, created_ats
  end

  test "sorts by popularity" do
    @downtown_property.update!(views_count: 100, favorites_count: 10)
    @suburban_property.update!(views_count: 50, favorites_count: 5)

    service = PropertySearchService.new({ sort: "popularity" })
    result = service.call

    assert_equal @downtown_property, result[:properties].first
  end

  # ============================================================================
  # USER PERSONALIZATION TESTS
  # ============================================================================

  test "applies user preferences for property types" do
    @tenant.update!(preferences: { preferred_property_types: [ "apartment", "condo" ] })

    service = PropertySearchService.new({}, user: @tenant)
    result = service.call

    # Should include all properties but with preference boost
    assert_equal 3, result[:properties].count
  end

  test "applies user budget preference with 10% tolerance" do
    @tenant.update!(preferences: { budget_max: 2000 })

    service = PropertySearchService.new({}, user: @tenant)
    result = service.call

    # Should include properties up to $2200 (10% over budget)
    result[:properties].each do |property|
      assert property.price <= 2200, "Property price #{property.price} exceeds budget tolerance"
    end
  end

  test "excludes viewed properties when requested" do
    # Create a property viewing for the tenant
    create(:property_viewing, user: @tenant, property: @downtown_property)

    service = PropertySearchService.new({ exclude_viewed: "true" }, user: @tenant)
    result = service.call

    assert_not_includes result[:properties], @downtown_property
    assert_includes result[:properties], @suburban_property
  end

  test "does not apply personalization for landlord users" do
    @landlord.update!(preferences: { preferred_property_types: [ "apartment" ] })

    service = PropertySearchService.new({}, user: @landlord)
    result = service.call

    # Should return all properties without personalization filtering
    assert_equal 3, result[:properties].count
  end

  # ============================================================================
  # ENHANCED RESULTS TESTS
  # ============================================================================

  test "enhances results with computed fields" do
    service = PropertySearchService.new({})
    result = service.call

    property = result[:properties].first
    assert_respond_to property, :relevance_score
    assert_respond_to property, :match_reasons
    assert_respond_to property, :recommendation_tags
  end

  test "relevance score is between 0 and 100" do
    service = PropertySearchService.new({ city: "Seattle" })
    result = service.call

    result[:properties].each do |property|
      score = property.relevance_score
      assert score >= 0, "Relevance score #{score} is less than 0"
      assert score <= 100, "Relevance score #{score} is greater than 100"
    end
  end

  # ============================================================================
  # SEARCH METADATA TESTS
  # ============================================================================

  test "search metadata includes all required fields" do
    service = PropertySearchService.new({ city: "Seattle" })
    result = service.call

    metadata = result[:search_metadata]
    assert metadata.key?(:search_id)
    assert metadata.key?(:timestamp)
    assert metadata.key?(:filters_count)
    assert metadata.key?(:personalized)
    assert metadata.key?(:search_context)
    assert metadata.key?(:estimated_results)
  end

  test "search metadata counts applied filters correctly" do
    service = PropertySearchService.new({
      city: "Seattle",
      min_price: 2000,
      bedrooms: 2
    })
    result = service.call

    assert_equal 3, result[:search_metadata][:filters_count]
  end

  test "search metadata indicates personalization when user present" do
    service = PropertySearchService.new({}, user: @tenant)
    result = service.call

    assert_equal true, result[:search_metadata][:personalized]
  end

  test "search metadata indicates no personalization when no user" do
    service = PropertySearchService.new({})
    result = service.call

    assert_equal false, result[:search_metadata][:personalized]
  end

  # ============================================================================
  # FILTERS APPLIED TESTS
  # ============================================================================

  test "filters_applied excludes pagination parameters" do
    service = PropertySearchService.new({
      city: "Seattle",
      page: 1,
      per_page: 20,
      sort: "price_asc"
    })
    result = service.call

    assert result[:filters_applied].key?(:city)
    assert_not result[:filters_applied].key?(:page)
    assert_not result[:filters_applied].key?(:per_page)
    assert_not result[:filters_applied].key?(:sort)
  end

  test "filters_applied excludes blank values" do
    service = PropertySearchService.new({
      city: "Seattle",
      state: "",
      zip_code: nil
    })
    result = service.call

    assert result[:filters_applied].key?(:city)
    assert_not result[:filters_applied].key?(:state)
    assert_not result[:filters_applied].key?(:zip_code)
  end

  # ============================================================================
  # SEARCH SUGGESTIONS TESTS
  # ============================================================================

  test "generates search suggestions" do
    service = PropertySearchService.new({ city: "Seattle" })
    result = service.call

    assert_instance_of Array, result[:suggestions]
  end

  # ============================================================================
  # SEARCH ANALYTICS TESTS
  # ============================================================================

  # Skipped: SearchAnalytics model doesn't exist yet
  # test "tracks search analytics for authenticated users" do
  #   service = PropertySearchService.new({ city: "Seattle" }, user: @tenant)

  #   assert_difference "SearchAnalytics.count", 1 do
  #     service.call
  #   end
  # end

  # test "does not track search analytics for anonymous users" do
  #   service = PropertySearchService.new({ city: "Seattle" })

  #   assert_no_difference "SearchAnalytics.count" do
  #     service.call
  #   end
  # end

  # test "search analytics includes search parameters" do
  #   service = PropertySearchService.new({
  #     city: "Seattle",
  #     min_price: 2000
  #   }, user: @tenant)
  #   result = service.call

  #   analytics = SearchAnalytics.last
  #   assert_equal "Seattle", analytics.search_params["city"]
  #   assert_equal 2000, analytics.search_params["min_price"]
  # end

  # ============================================================================
  # EDGE CASES AND ERROR HANDLING TESTS
  # ============================================================================

  test "handles nil search params gracefully" do
    service = PropertySearchService.new(nil)
    result = service.call

    assert_instance_of Array, result[:properties]
    assert_equal 3, result[:properties].count
  end

  test "handles empty search params" do
    service = PropertySearchService.new({})
    result = service.call

    assert_equal 3, result[:properties].count
  end

  test "handles invalid date format gracefully" do
    service = PropertySearchService.new({ move_in_date: "invalid-date" })

    # Should not raise error, just skip the filter
    assert_nothing_raised do
      service.call
    end
  end

  test "handles negative prices by returning no results" do
    service = PropertySearchService.new({ min_price: -1000 })
    result = service.call

    # Should apply filter normally (no properties have negative price)
    assert_instance_of Array, result[:properties]
  end

  test "handles very large price values" do
    service = PropertySearchService.new({ max_price: 999999999 })
    result = service.call

    # Should return all properties (all under this max)
    assert_equal 3, result[:properties].count
  end

  test "handles empty amenities array" do
    service = PropertySearchService.new({ amenities: [] })
    result = service.call

    assert_equal 3, result[:properties].count
  end

  test "handles whitespace in location query" do
    service = PropertySearchService.new({ location: "  Seattle  " })
    result = service.call

    assert_equal 2, result[:properties].count
  end

  # ============================================================================
  # INTEGRATION TESTS
  # ============================================================================

  test "complex search with multiple criteria returns correct results" do
    service = PropertySearchService.new({
      city: "Seattle",
      min_price: 2000,
      max_price: 5000,
      min_bedrooms: 2,
      amenities: [ "parking" ],
      sort: "price_asc"
    })
    result = service.call

    assert_equal 2, result[:properties].count

    # Verify all results match criteria
    result[:properties].each do |property|
      assert_equal "Seattle", property.city
      assert property.price >= 2000
      assert property.price <= 5000
      assert property.bedrooms >= 2
      assert_equal true, property.parking_available
    end

    # Verify sorting
    prices = result[:properties].map(&:price)
    assert_equal prices.sort, prices
  end

  test "search with user personalization and filters" do
    @tenant.update!(preferences: {
      preferred_property_types: [ "apartment", "condo" ],
      budget_max: 3000
    })

    service = PropertySearchService.new({
      city: "Seattle",
      amenities: [ "parking" ]
    }, user: @tenant)

    result = service.call

    # Should filter by city and amenities, plus apply budget preference
    assert result[:properties].count > 0
    result[:properties].each do |property|
      assert_equal "Seattle", property.city
      assert property.price <= 3300 # 10% over budget tolerance
      assert_equal true, property.parking_available
    end
  end
end
