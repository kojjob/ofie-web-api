require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = create(:user, :landlord, password: "password123")
    @property = create(:property, user: @user)
    post login_url, params: { email: @user.email, password: "password123" }
  end

  test "should get index" do
    get properties_url
    assert_response :success
  end

  test "should get show" do
    get property_url(@property)
    assert_response :success
  end

  test "should get new" do
    get new_property_url
    assert_response :success
  end

  test "should create property" do
    assert_difference("Property.count") do
      post properties_url, params: { property: {
        title: "Test Property",
        description: "Test Description",
        price: 1000,
        address: "Test Address",
        city: "Test City",
        property_type: "apartment",
        bedrooms: 2,
        bathrooms: 1,
        availability_status: "available"
      } }
    end

    created_property = Property.find_by(title: "Test Property")
    assert_redirected_to property_url(created_property)
  end

  test "should get edit" do
    get edit_property_url(@property)
    assert_response :success
  end

  test "should update property" do
    patch property_url(@property), params: { property: { title: "Updated Title" } }
    assert_redirected_to property_url(@property)
  end

  test "should destroy property" do
    assert_difference("Property.count", -1) do
      delete property_url(@property)
    end
    assert_redirected_to properties_url
  end
end
