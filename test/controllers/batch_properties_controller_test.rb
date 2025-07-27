require "test_helper"

class BatchPropertiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @landlord = users(:landlord)
    @tenant = users(:tenant)
    @agent = users(:agent) if users(:agent)
    
    # Create test CSV files
    @valid_csv_content = <<~CSV
      title,description,address,city,state,postal_code,price,bedrooms,bathrooms,area,property_type,listing_type
      "Modern Downtown Condo","Luxury 2BR condo with amazing views","123 Main St","San Francisco","CA","94105",3500,2,2,1200,apartment,rent
      "Spacious Family Home","Beautiful 4BR house in quiet neighborhood","456 Oak Ave","San Francisco","CA","94110",750000,4,3,2500,house,sale
    CSV
    
    @invalid_csv_content = <<~CSV
      title,price
      "Incomplete Property",
    CSV
    
    @malformed_csv_content = "This is not, a valid CSV\nfile at all"
  end

  # Template Download Tests
  test "should download CSV template for authenticated landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get template_batch_properties_path(format: :csv)

    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match /property_listing_template_\d{8}\.csv/, response.headers["Content-Disposition"]

    # Verify CSV structure
    csv = CSV.parse(response.body, headers: true)
    required_headers = %w[title description address city state postal_code price bedrooms bathrooms area property_type listing_type]
    assert_equal required_headers.sort, csv.headers.sort
    
    # Verify example row exists
    assert_equal 1, csv.size
    assert_equal "Beautiful 2BR Apartment Downtown", csv.first["title"]
  end

  test "should redirect tenant trying to download template" do
    post login_path, params: { email: @tenant.email, password: "password123" }
    get template_batch_properties_path(format: :csv)

    assert_redirected_to properties_path
    assert_match /landlord/, flash[:alert]
  end

  test "should redirect unauthenticated user trying to download template" do
    get template_batch_properties_path(format: :csv)

    assert_redirected_to login_path
    assert_match /sign in/, flash[:alert]
  end

  # Index Tests
  test "should access batch properties index for landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get batch_properties_path

    assert_response :success
    assert_select "h1", "Batch Property Listing"
    assert_select "[data-controller='batch-properties']"
    assert_select "a[href='#{template_batch_properties_path(format: :csv)}']", "Download Template"
  end

  test "should show upload history in index" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    # Create some upload history
    upload1 = BatchPropertyUpload.create!(
      user: @landlord,
      file_name: "properties_batch_1.csv",
      status: "completed",
      total_rows: 10,
      successful_rows: 9,
      failed_rows: 1
    )
    
    upload2 = BatchPropertyUpload.create!(
      user: @landlord,
      file_name: "properties_batch_2.csv",
      status: "processing",
      total_rows: 5,
      successful_rows: 0,
      failed_rows: 0
    )
    
    get batch_properties_path
    
    assert_response :success
    assert_select ".upload-history-item", 2
    assert_select ".status-completed", 1
    assert_select ".status-processing", 1
  end

  test "should redirect tenant from batch properties index" do
    post login_path, params: { email: @tenant.email, password: "password123" }
    get batch_properties_path

    assert_redirected_to properties_path
    assert_match /landlord/, flash[:alert]
  end

  # New Upload Tests
  test "should show new upload form for landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get new_batch_property_path

    assert_response :success
    assert_select "form[data-controller='file-upload']"
    assert_select "input[type='file'][accept='.csv']"
    assert_select ".upload-instructions"
  end

  # Create/Upload Tests
  test "should create batch upload with valid CSV file" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    csv_file = Rack::Test::UploadedFile.new(
      StringIO.new(@valid_csv_content),
      "text/csv",
      original_filename: "properties.csv"
    )
    
    assert_difference "BatchPropertyUpload.count", 1 do
      post batch_properties_path, params: {
        batch_property_upload: { file: csv_file }
      }
    end
    
    upload = BatchPropertyUpload.last
    assert_equal @landlord, upload.user
    assert_equal "properties.csv", upload.file_name
    assert_equal "pending", upload.status
    assert_equal 2, upload.total_rows
    
    assert_redirected_to batch_property_path(upload)
    assert_match /upload.*queued/, flash[:notice]
  end

  test "should reject upload without CSV file" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    assert_no_difference "BatchPropertyUpload.count" do
      post batch_properties_path, params: {
        batch_property_upload: { file: nil }
      }
    end
    
    assert_response :unprocessable_entity
    assert_select ".error", /file.*required/i
  end

  test "should reject non-CSV file upload" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    txt_file = Rack::Test::UploadedFile.new(
      StringIO.new("This is a text file"),
      "text/plain",
      original_filename: "properties.txt"
    )
    
    assert_no_difference "BatchPropertyUpload.count" do
      post batch_properties_path, params: {
        batch_property_upload: { file: txt_file }
      }
    end
    
    assert_response :unprocessable_entity
    assert_select ".error", /CSV.*only/i
  end

  test "should validate CSV headers before upload" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    csv_file = Rack::Test::UploadedFile.new(
      StringIO.new(@invalid_csv_content),
      "text/csv",
      original_filename: "invalid.csv"
    )
    
    assert_no_difference "BatchPropertyUpload.count" do
      post batch_properties_path, params: {
        batch_property_upload: { file: csv_file }
      }
    end
    
    assert_response :unprocessable_entity
    assert_select ".error", /missing.*required.*columns/i
  end

  # Show/Status Tests
  test "should show batch upload status for owner" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      file_name: "test.csv",
      status: "processing",
      total_rows: 10,
      successful_rows: 5,
      failed_rows: 0
    )
    
    get batch_property_path(upload)
    
    assert_response :success
    assert_select ".upload-status", /processing/i
    assert_select ".progress-bar"
    assert_select "[data-batch-upload-id='#{upload.id}']"
  end

  test "should not show other user's batch upload" do
    other_landlord = User.create!(
      email: "other@example.com",
      password: "password123",
      full_name: "Other Landlord",
      user_type: "landlord"
    )
    
    upload = BatchPropertyUpload.create!(
      user: other_landlord,
      file_name: "private.csv",
      status: "completed"
    )
    
    post login_path, params: { email: @landlord.email, password: "password123" }
    get batch_property_path(upload)
    
    assert_response :not_found
  end

  # Preview Tests
  test "should preview CSV file before upload" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    post preview_batch_properties_path, params: {
      file: Rack::Test::UploadedFile.new(
        StringIO.new(@valid_csv_content),
        "text/csv"
      )
    }, xhr: true
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert json["valid"]
    assert_equal 2, json["row_count"]
    assert_equal 12, json["headers"].size
    assert_empty json["errors"]
    assert_equal "Modern Downtown Condo", json["preview_rows"].first["title"]
  end

  test "should show errors in CSV preview" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    post preview_batch_properties_path, params: {
      file: Rack::Test::UploadedFile.new(
        StringIO.new(@malformed_csv_content),
        "text/csv"
      )
    }, xhr: true
    
    assert_response :success
    json = JSON.parse(response.body)
    
    assert_not json["valid"]
    assert_not_empty json["errors"]
  end

  # Retry Failed Items Tests
  test "should retry failed batch items" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      file_name: "test.csv",
      status: "completed_with_errors",
      total_rows: 10,
      successful_rows: 8,
      failed_rows: 2
    )
    
    # Create failed items
    2.times do |i|
      BatchPropertyItem.create!(
        batch_property_upload: upload,
        row_number: i + 1,
        status: "failed",
        error_message: "Invalid data",
        row_data: { title: "Failed Property #{i}" }
      )
    end
    
    post retry_batch_property_path(upload), xhr: true
    
    assert_response :success
    
    # Check that failed items are reset to pending
    upload.batch_property_items.where(status: "failed").each do |item|
      assert_equal "pending", item.reload.status
    end
  end

  # Download Results Tests
  test "should download results CSV" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      file_name: "test.csv",
      status: "completed",
      total_rows: 2,
      successful_rows: 1,
      failed_rows: 1
    )
    
    # Create result items
    BatchPropertyItem.create!(
      batch_property_upload: upload,
      row_number: 1,
      status: "success",
      property_id: properties(:property_one).id,
      row_data: { title: "Success Property" }
    )
    
    BatchPropertyItem.create!(
      batch_property_upload: upload,
      row_number: 2,
      status: "failed",
      error_message: "Price must be positive",
      row_data: { title: "Failed Property", price: -100 }
    )
    
    get results_batch_property_path(upload, format: :csv)
    
    assert_response :success
    assert_equal "text/csv", response.content_type
    
    csv = CSV.parse(response.body, headers: true)
    assert_equal 2, csv.size
    assert_equal "success", csv[0]["status"]
    assert_equal "failed", csv[1]["status"]
    assert_equal "Price must be positive", csv[1]["error"]
  end

  # WebSocket/Turbo Stream Tests
  test "should stream upload progress updates" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      file_name: "test.csv",
      status: "processing",
      total_rows: 100
    )
    
    # Simulate progress update
    upload.update!(successful_rows: 50, failed_rows: 5)
    
    # In a real test, you would verify Turbo Stream broadcasts
    # For now, we'll just verify the data is correct
    assert_equal 55, upload.processed_rows
    assert_equal 55.0, upload.progress_percentage
  end

  private

  def sign_in_as(user)
    post login_path, params: { email: user.email, password: "password123" }
  end
end