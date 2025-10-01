require "test_helper"

class PropertyRecommendationEngineTest < ActiveSupport::TestCase
  def setup
    # Create test users
    @tenant_user = create(:user, :tenant, preferences: {
      preferred_property_types: [ "apartment", "condo" ],
      preferred_locations: [ "Seattle", "Bellevue" ],
      preferred_amenities: [ "gym", "pool", "parking" ],
      budget_max: 2500,
      preferred_bedrooms: 2
    })
    @landlord_user = create(:user, :landlord)
    @other_tenant = create(:user, :tenant)

    # Create test properties with various characteristics
    @property1 = create(:property,
      title: "Downtown Apartment",
      property_type: "apartment",
      city: "Seattle",
      price: 2000,
      bedrooms: 2,
      bathrooms: 1,
      gym: true,
      pool: true,
      parking_available: true,
      status: "active",
      availability_status: "available")

    @property2 = create(:property,
      title: "Luxury Condo",
      property_type: "condo",
      city: "Bellevue",
      price: 2400,
      bedrooms: 2,
      bathrooms: 2,
      gym: true,
      pool: false,
      parking_available: true,
      balcony: true,
      status: "active",
      availability_status: "available")

    @property3 = create(:property,
      title: "Budget House",
      property_type: "house",
      city: "Tacoma",
      price: 1500,
      bedrooms: 3,
      bathrooms: 2,
      gym: false,
      pool: false,
      parking_available: true,
      status: "active",
      availability_status: "available")

    @property4 = create(:property,
      title: "Premium Apartment",
      property_type: "apartment",
      city: "Seattle",
      price: 3500,
      bedrooms: 3,
      bathrooms: 2,
      gym: true,
      pool: true,
      parking_available: true,
      balcony: true,
      air_conditioning: true,
      status: "active",
      availability_status: "available")

    @unavailable_property = create(:property,
      property_type: "apartment",
      city: "Seattle",
      status: "active",
      availability_status: "rented")
  end

  # Basic Recommendation Tests
  test "recommend returns properties" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    assert_not_nil recommendations
    assert_kind_of Array, recommendations
    assert recommendations.size <= 20
  end

  test "recommend filters out unavailable properties" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    assert_not_includes recommendations, @unavailable_property
  end

  test "recommend applies budget filter" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(budget: 2000)

    recommendations.each do |property|
      assert property.price <= 2000, "Property #{property.title} price #{property.price} exceeds budget"
    end
  end

  test "recommend applies property type filter" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(property_type: "apartment")

    recommendations.each do |property|
      assert_equal "apartment", property.property_type
    end
  end

  test "recommend applies bedroom count filter" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(bedroom_count: 2)

    recommendations.each do |property|
      assert_equal 2, property.bedrooms
    end
  end

  test "recommend applies bathroom count filter" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(bathroom_count: 2)

    recommendations.each do |property|
      assert_equal 2, property.bathrooms
    end
  end

  test "recommend applies price range filter" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(price_range: { min: 1500, max: 2500 })

    recommendations.each do |property|
      assert property.price >= 1500 && property.price <= 2500,
             "Property price #{property.price} outside range 1500-2500"
    end
  end

  test "recommend applies location filter with city" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(location: "Seattle")

    assert recommendations.all? { |p| p.city == "Seattle" }
  end

  test "recommend applies location filter with multiple terms" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(location: "Seattle, Bellevue")

    assert recommendations.all? { |p| [ "Seattle", "Bellevue" ].include?(p.city) }
  end

  test "recommend applies single amenity filter" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(amenities: [ "gym" ])

    recommendations.each do |property|
      assert_equal true, property.gym
    end
  end

  test "recommend applies multiple amenity filters" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(amenities: [ "gym", "pool" ])

    recommendations.each do |property|
      assert_equal true, property.gym
      assert_equal true, property.pool
    end
  end

  test "recommend handles pet amenity filter" do
    @property1.update!(pets_allowed: true)
    @property2.update!(pets_allowed: false)
    @property3.update!(pets_allowed: false)
    @property4.update!(pets_allowed: false)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend(amenities: [ "pets" ])

    assert_equal 1, recommendations.size
    assert_includes recommendations, @property1
  end

  # Scoring Tests
  test "properties receive preference scores" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    recommendations.each do |property|
      assert property.respond_to?(:preference_score)
    end
  end

  test "properties receive collaborative scores" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    recommendations.each do |property|
      assert property.respond_to?(:collaborative_score)
    end
  end

  test "properties receive behavioral scores" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    recommendations.each do |property|
      assert property.respond_to?(:behavioral_score)
    end
  end

  test "properties receive market scores" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    recommendations.each do |property|
      assert property.respond_to?(:market_score)
    end
  end

  test "recommendations are sorted by total score" do
    # Create multiple viewings for property1 to boost its market score
    5.times do
      create(:property_viewing, property: @property1, user: @other_tenant)
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    recommendations = engine.recommend

    # Property with more viewings and matching preferences should rank higher
    property1_index = recommendations.index(@property1)
    property3_index = recommendations.index(@property3)

    if property1_index && property3_index
      assert property1_index < property3_index,
             "Property with better score should rank higher"
    end
  end

  # Similar Properties Tests
  test "get_similar_properties returns similar properties" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    assert_not_nil similar
    assert_kind_of Array, similar
    assert similar.size <= 5
  end

  test "get_similar_properties excludes the source property" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    assert_not_includes similar, @property1
  end

  test "get_similar_properties matches property type" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    similar.each do |property|
      assert_equal @property1.property_type, property.property_type
    end
  end

  test "get_similar_properties matches city" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    similar.each do |property|
      assert_equal @property1.city, property.city
    end
  end

  test "get_similar_properties finds properties with similar bedrooms" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    similar.each do |property|
      bedroom_diff = (property.bedrooms - @property1.bedrooms).abs
      assert bedroom_diff <= 1, "Bedroom difference too large"
    end
  end

  test "get_similar_properties finds properties with similar price" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    min_price = @property1.price * 0.8
    max_price = @property1.price * 1.2

    similar.each do |property|
      assert property.price >= min_price && property.price <= max_price,
             "Price #{property.price} outside range #{min_price}-#{max_price}"
    end
  end

  test "get_similar_properties respects custom limit" do
    # Create more similar properties
    3.times do
      create(:property,
        property_type: @property1.property_type,
        city: @property1.city,
        bedrooms: @property1.bedrooms,
        price: @property1.price + 50,
        status: "active",
        availability_status: "available")
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1, 2)

    assert_equal 2, similar.size
  end

  test "get_similar_properties sorts by similarity score" do
    # Create a very similar property (same everything except slight price difference)
    very_similar = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms,
      bathrooms: @property1.bathrooms,
      price: @property1.price + 10,
      gym: @property1.gym,
      pool: @property1.pool,
      status: "active",
      availability_status: "available")

    # Create a less similar property
    less_similar = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms + 1,
      bathrooms: @property1.bathrooms + 1,
      price: @property1.price * 1.15,
      gym: false,
      pool: false,
      status: "active",
      availability_status: "available")

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar = engine.get_similar_properties(@property1)

    # Very similar property should rank higher than less similar
    very_similar_index = similar.index(very_similar)
    less_similar_index = similar.index(less_similar)

    if very_similar_index && less_similar_index
      assert very_similar_index < less_similar_index,
             "More similar property should rank higher"
    end
  end

  # Trending Properties Tests
  test "get_trending_properties returns properties" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    trending = engine.get_trending_properties

    assert_not_nil trending
    assert_kind_of Array, trending
  end

  test "get_trending_properties returns properties with recent viewings" do
    # Create recent viewings for property1
    3.times do
      create(:property_viewing, property: @property1, user: @other_tenant)
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    trending = engine.get_trending_properties

    assert_includes trending, @property1
  end

  test "get_trending_properties orders by viewing count" do
    # Property1 gets more viewings than property2
    5.times { create(:property_viewing, property: @property1, user: @other_tenant) }
    2.times { create(:property_viewing, property: @property2, user: @other_tenant) }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    trending = engine.get_trending_properties

    property1_index = trending.to_a.index(@property1)
    property2_index = trending.to_a.index(@property2)

    if property1_index && property2_index
      assert property1_index < property2_index,
             "Property with more viewings should rank higher"
    end
  end

  test "get_trending_properties respects limit" do
    # Create viewings for multiple properties
    [ @property1, @property2, @property3 ].each do |property|
      create(:property_viewing, property: property, user: @other_tenant)
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    trending = engine.get_trending_properties(2)

    assert_equal 2, trending.size
  end

  test "get_trending_properties only includes recent viewings" do
    # Create old viewing (outside 1 week window)
    old_viewing = create(:property_viewing,
      property: @property1,
      user: @other_tenant,
      created_at: 2.weeks.ago)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    trending = engine.get_trending_properties

    # Property1 should not appear if only old viewings exist
    assert_not_includes trending.to_a, @property1
  end

  # Personalized Recommendations Tests
  test "get_personalized_recommendations returns properties" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    personalized = engine.get_personalized_recommendations

    assert_not_nil personalized
    assert_kind_of Array, personalized
  end

  test "get_personalized_recommendations respects limit" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    personalized = engine.get_personalized_recommendations(5)

    assert personalized.size <= 5
  end

  test "get_personalized_recommendations for landlord returns trending" do
    engine = PropertyRecommendationEngine.new(@landlord_user)
    personalized = engine.get_personalized_recommendations

    # For landlords, should return trending properties
    assert_not_nil personalized
  end

  test "get_personalized_recommendations uses user preferences" do
    # Create rental applications to establish preferences
    2.times do
      property = create(:property,
        property_type: "apartment",
        city: "Seattle",
        price: 2200,
        bedrooms: 2,
        status: "active",
        availability_status: "available")
      create(:rental_application, tenant: @tenant_user, property: property)
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    personalized = engine.get_personalized_recommendations

    # Should prefer properties matching application history
    assert personalized.any? { |p| p.property_type == "apartment" }
  end

  test "get_personalized_recommendations considers favorites" do
    @tenant_user.favorite_properties << @property1

    engine = PropertyRecommendationEngine.new(@tenant_user)
    personalized = engine.get_personalized_recommendations

    # Should boost similar properties to favorites
    similar_properties = personalized.select { |p|
      p.property_type == @property1.property_type &&
      p.city == @property1.city
    }

    assert similar_properties.any?, "Should include properties similar to favorites"
  end

  test "get_personalized_recommendations considers viewing history" do
    # Create viewings for property1
    3.times do
      create(:property_viewing, property: @property1, user: @tenant_user)
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    personalized = engine.get_personalized_recommendations

    # Should consider viewing patterns in recommendations
    assert_not_nil personalized
  end

  # User Preference Extraction Tests
  test "extracts preferences from user behavior" do
    # Create applications to establish preferences
    create(:rental_application, tenant: @tenant_user, property: @property1) # apartment, Seattle
    create(:rental_application, tenant: @tenant_user, property: @property2) # condo, Bellevue

    engine = PropertyRecommendationEngine.new(@tenant_user)
    preferences = engine.send(:get_user_preferences)

    # Should extract location and type preferences from applications
    assert preferences[:preferred_locations].present?
    assert preferences[:preferred_property_types].present?
  end

  test "extracts price range from rental applications" do
    create(:rental_application,
      tenant: @tenant_user,
      property: @property1) # $2000
    create(:rental_application,
      tenant: @tenant_user,
      property: @property2) # $2400

    engine = PropertyRecommendationEngine.new(@tenant_user)
    preferences = engine.send(:get_user_preferences)

    assert_not_nil preferences[:preferred_price_range]
    assert_equal 2000, preferences[:preferred_price_range][:min]
    assert_equal 2400, preferences[:preferred_price_range][:max]
  end

  test "extracts location preferences from applications" do
    create(:rental_application, tenant: @tenant_user, property: @property1) # Seattle
    create(:rental_application, tenant: @tenant_user, property: @property2) # Bellevue

    engine = PropertyRecommendationEngine.new(@tenant_user)
    preferences = engine.send(:get_user_preferences)

    assert_includes preferences[:preferred_locations], "Seattle"
    assert_includes preferences[:preferred_locations], "Bellevue"
  end

  test "extracts property type preferences from applications" do
    create(:rental_application, tenant: @tenant_user, property: @property1) # apartment
    create(:rental_application, tenant: @tenant_user, property: @property2) # condo

    engine = PropertyRecommendationEngine.new(@tenant_user)
    preferences = engine.send(:get_user_preferences)

    assert_includes preferences[:preferred_property_types], "apartment"
    assert_includes preferences[:preferred_property_types], "condo"
  end

  test "analyzes viewing patterns" do
    3.times { create(:property_viewing, property: @property1, user: @tenant_user) }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    preferences = engine.send(:get_user_preferences)

    assert_not_nil preferences[:viewing_patterns]
    assert preferences[:viewing_patterns].key?(:avg_viewings_per_property)
  end

  test "analyzes favorite patterns" do
    @tenant_user.favorite_properties << @property1
    @tenant_user.favorite_properties << @property2

    engine = PropertyRecommendationEngine.new(@tenant_user)
    preferences = engine.send(:get_user_preferences)

    assert_not_nil preferences[:favorite_patterns]
    assert preferences[:favorite_patterns].key?(:preferred_types)
  end

  # Preference Scoring Tests
  test "preference score rewards price match" do
    preferences = {
      preferred_price_range: { min: 1900, max: 2100 }
    }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_preference_score, @property1, preferences)

    assert score > 0, "Should reward properties within price range"
  end

  test "preference score rewards location match" do
    preferences = {
      preferred_locations: [ "Seattle" ]
    }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_preference_score, @property1, preferences)

    assert score >= 15, "Should give 15 points for location match"
  end

  test "preference score rewards property type match" do
    preferences = {
      preferred_property_types: [ "apartment" ]
    }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_preference_score, @property1, preferences)

    assert score >= 10, "Should give 10 points for property type match"
  end

  test "preference score rewards bedroom match" do
    preferences = {
      preferred_bedrooms: 2
    }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_preference_score, @property1, preferences)

    assert score >= 10, "Should give 10 points for exact bedroom match"
  end

  test "preference score gives partial points for near bedroom match" do
    preferences = {
      preferred_bedrooms: 1
    }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_preference_score, @property1, preferences)

    assert score >= 5, "Should give 5 points for 1 bedroom difference"
  end

  test "preference score rewards amenity matches" do
    preferences = {
      preferred_amenities: [ "gym", "pool" ]
    }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_preference_score, @property1, preferences)

    # Should get points for each matching amenity
    assert score > 0, "Should reward matching amenities"
  end

  # Collaborative Filtering Tests
  test "finds similar users based on application patterns" do
    # Create similar applications for other user
    create(:rental_application,
      tenant: @other_tenant,
      property: create(:property,
        property_type: "apartment",
        city: "Seattle",
        status: "active",
        availability_status: "available"))

    create(:rental_application,
      tenant: @tenant_user,
      property: @property1) # apartment in Seattle

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar_users = engine.send(:find_similar_users)

    assert similar_users.any?, "Should find users with similar preferences"
  end

  test "calculates user similarity score" do
    # Create similar preferences
    similar_property = create(:property,
      property_type: "apartment",
      city: "Seattle",
      status: "active",
      availability_status: "available")

    create(:rental_application, tenant: @tenant_user, property: @property1)
    create(:rental_application, tenant: @other_tenant, property: similar_property)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similarity = engine.send(:calculate_user_similarity, @other_tenant)

    assert similarity > 0, "Should calculate positive similarity for similar preferences"
  end

  test "collaborative score considers similar user applications" do
    # Other user applied to property1
    create(:rental_application, tenant: @other_tenant, property: @property1)

    # Make other_tenant similar to @tenant_user
    create(:rental_application, tenant: @tenant_user, property: @property2)
    create(:rental_application, tenant: @other_tenant, property: @property2)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar_users = [ @other_tenant ]
    score = engine.send(:calculate_collaborative_score, @property1, similar_users)

    assert score > 0, "Should boost properties similar users applied to"
  end

  test "collaborative score considers favorites" do
    @other_tenant.favorite_properties << @property1

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar_users = [ @other_tenant ]
    score = engine.send(:calculate_collaborative_score, @property1, similar_users)

    assert score > 0, "Should boost properties similar users favorited"
  end

  # Behavioral Scoring Tests
  test "analyzes user behavior patterns" do
    create(:rental_application, tenant: @tenant_user, property: @property1)
    create(:rental_application, tenant: @tenant_user, property: @property2)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    behavior = engine.send(:analyze_user_behavior)

    assert_not_nil behavior
    assert behavior.key?(:price_sensitivity)
    assert behavior.key?(:amenity_importance)
  end

  test "calculates price sensitivity from application variance" do
    # Create applications with consistent pricing
    [ 2000, 2100, 2200 ].each do |price|
      property = create(:property,
        price: price,
        status: "active",
        availability_status: "available")
      create(:rental_application, tenant: @tenant_user, property: property)
    end

    engine = PropertyRecommendationEngine.new(@tenant_user)
    price_sensitivity = engine.send(:calculate_price_sensitivity)

    assert_not_nil price_sensitivity
    assert [ :low, :moderate, :high, :unknown ].include?(price_sensitivity)
  end

  test "calculates amenity importance from favorites and applications" do
    # Create properties with specific amenities
    @tenant_user.favorite_properties << @property1 # has gym, pool
    create(:rental_application, tenant: @tenant_user, property: @property1)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    amenity_importance = engine.send(:calculate_amenity_importance)

    assert_not_nil amenity_importance
    assert amenity_importance.key?(:high_importance)
  end

  # Market Scoring Tests
  test "market score rewards recent activity" do
    5.times { create(:property_viewing, property: @property1, user: @other_tenant) }

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_market_score, @property1)

    assert score > 0, "Should reward properties with recent viewings"
  end

  test "market score rewards competitive pricing" do
    # Create similar properties to establish market average (need > 5 for pricing logic)
    5.times do
      create(:property,
        property_type: @property1.property_type,
        city: @property1.city,
        bedrooms: @property1.bedrooms,
        price: 2500,
        status: "active",
        availability_status: "available")
    end

    # Property1 at $2000 is below market average of $2500 (5% below)
    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_market_score, @property1)

    assert score >= 8, "Should reward competitively priced properties (8 points for 5%+ below average)"
  end

  test "market score rewards property quality indicators" do
    # Mock the photos count for quality scoring
    @property1.define_singleton_method(:photos) do
      photos_mock = Object.new
      photos_mock.define_singleton_method(:attached?) { true }
      photos_mock.define_singleton_method(:count) { 6 }
      photos_mock
    end

    # Mock description for quality scoring
    @property1.update!(description: "A" * 250)

    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_market_score, @property1)

    assert score >= 5, "Should give points for having 5+ photos and description"
  end

  # Similarity Scoring Tests
  test "calculates similarity score for properties" do
    engine = PropertyRecommendationEngine.new(@tenant_user)
    score = engine.send(:calculate_similarity_score, @property1, @property2)

    assert score > 0, "Should calculate positive similarity score"
    assert score <= 100, "Similarity score should not exceed maximum"
  end

  test "similarity score considers price difference" do
    similar_price_property = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms,
      bathrooms: @property1.bathrooms,
      price: @property1.price + 50, # very close price
      status: "active",
      availability_status: "available")

    different_price_property = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms,
      bathrooms: @property1.bathrooms,
      price: @property1.price * 2, # double the price
      status: "active",
      availability_status: "available")

    engine = PropertyRecommendationEngine.new(@tenant_user)
    similar_score = engine.send(:calculate_similarity_score, @property1, similar_price_property)
    different_score = engine.send(:calculate_similarity_score, @property1, different_price_property)

    assert similar_score > different_score,
           "Properties with similar prices should score higher"
  end

  test "similarity score gives high weight to same city" do
    same_city_property = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms + 1,
      price: @property1.price * 1.5,
      status: "active",
      availability_status: "available")

    different_city_property = create(:property,
      property_type: @property1.property_type,
      city: "Portland",
      bedrooms: @property1.bedrooms,
      price: @property1.price,
      status: "active",
      availability_status: "available")

    engine = PropertyRecommendationEngine.new(@tenant_user)
    same_city_score = engine.send(:calculate_similarity_score, @property1, same_city_property)
    different_city_score = engine.send(:calculate_similarity_score, @property1, different_city_property)

    # Same city should get 25 points bonus
    assert same_city_score > different_city_score + 20,
           "Same city should significantly boost similarity score"
  end

  test "similarity score considers amenity overlap" do
    many_amenities_property = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms,
      price: @property1.price,
      gym: @property1.gym,
      pool: @property1.pool,
      balcony: true,
      air_conditioning: true,
      status: "active",
      availability_status: "available")

    few_amenities_property = create(:property,
      property_type: @property1.property_type,
      city: @property1.city,
      bedrooms: @property1.bedrooms,
      price: @property1.price,
      gym: false,
      pool: false,
      status: "active",
      availability_status: "available")

    engine = PropertyRecommendationEngine.new(@tenant_user)
    many_score = engine.send(:calculate_similarity_score, @property1, many_amenities_property)
    few_score = engine.send(:calculate_similarity_score, @property1, few_amenities_property)

    assert many_score > few_score,
           "Properties with more common amenities should score higher"
  end

  # Total Score Calculation Tests
  test "calculates total score from all components" do
    engine = PropertyRecommendationEngine.new(@tenant_user)

    # Set up property with all score types
    @property1.define_singleton_method(:preference_score) { 50 }
    @property1.define_singleton_method(:collaborative_score) { 10 }
    @property1.define_singleton_method(:behavioral_score) { 15 }
    @property1.define_singleton_method(:market_score) { 10 }

    total_score = engine.send(:calculate_total_score, @property1)

    # Base score (50) + weighted component scores
    expected_minimum = 50
    assert total_score >= expected_minimum,
           "Total score should include base score and components"
  end

  test "total score applies quality multipliers" do
    engine = PropertyRecommendationEngine.new(@tenant_user)

    # Mock average_rating method for property
    @property1.define_singleton_method(:average_rating) { 4.5 }
    @property1.define_singleton_method(:preference_score) { 0 }
    @property1.define_singleton_method(:collaborative_score) { 0 }
    @property1.define_singleton_method(:behavioral_score) { 0 }
    @property1.define_singleton_method(:market_score) { 0 }

    total_score = engine.send(:calculate_total_score, @property1)

    # Should have base score (50) multiplied by 1.2 for high rating
    assert total_score >= 60, "Should apply 1.2x multiplier for rating > 4.0"
  end
end
