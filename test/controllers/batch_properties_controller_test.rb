require "test_helper"

class BatchPropertiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @landlord = users(:landlord)
    @tenant = users(:tenant)
  end

  test "should download CSV template for authenticated landlord" do
    # Simulate landlord login
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    # Request CSV template
    get template_batch_properties_path(format: :csv)
    
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match /property_listing_template_\d{8}\.csv/, response.headers["Content-Disposition"]
    
    # Verify CSV content has headers
    csv_content = response.body
    assert_includes csv_content, "title,description,address,city,price"
    assert_includes csv_content, "Beautiful 2BR Apartment Downtown"
  end

  test "should redirect tenant trying to download template" do
    # Simulate tenant login
    post login_path, params: { email: @tenant.email, password: "password123" }
    
    # Request CSV template
    get template_batch_properties_path(format: :csv)
    
    assert_redirected_to properties_path
    assert_match /landlord/, flash[:alert]
  end

  test "should redirect unauthenticated user trying to download template" do
    # Request CSV template without login
    get template_batch_properties_path(format: :csv)
    
    assert_redirected_to login_path
    assert_match /sign in/, flash[:alert]
  end

  test "should access batch properties index for landlord" do
    # Simulate landlord login
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    get batch_properties_path
    
    assert_response :success
    assert_select "h1", "Batch Property Listing"
  end

  test "should redirect tenant from batch properties index" do
    # Simulate tenant login
    post login_path, params: { email: @tenant.email, password: "password123" }
    
    get batch_properties_path
    
    assert_redirected_to properties_path
    assert_match /landlord/, flash[:alert]
  end
end
