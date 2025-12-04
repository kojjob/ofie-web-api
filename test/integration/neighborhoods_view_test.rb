require "test_helper"

class NeighborhoodsViewTest < ActionDispatch::IntegrationTest
  test "neighborhoods page renders successfully" do
    get neighborhoods_path
    assert_response :success
    assert_select "h1", "Explore Neighborhoods"
  end

  test "neighborhoods page shows neighborhood cards when data exists" do
    # Create test user and properties in different cities
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      name: "Test User",
      role: "landlord"
    )

    Property.create!(
      title: "Test Property 1",
      city: "San Diego",
      address: "123 Test St",
      price: 1500,
      bedrooms: 2,
      bathrooms: 1,
      square_feet: 1000,
      property_type: "apartment",
      availability_status: "available",
      user: user
    )

    get neighborhoods_path
    assert_response :success
    assert_select ".neighborhood-card", minimum: 1
    assert_select "h2", "Featured Neighborhoods"
  end

  test "neighborhoods page shows empty state when no data exists" do
    # Delete all properties
    Property.delete_all

    get neighborhoods_path
    assert_response :success
    assert_select "h2", "No Neighborhoods Available"
  end
end
