require "test_helper"

class BatchPropertiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @landlord = create(:user, :landlord, :verified)
    @tenant = create(:user, :tenant, :verified)
    @property = create(:property, user: @landlord)
  end

  # Template Download Tests
  test "should download CSV template for authenticated landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get template_batch_properties_path(format: :csv)

    assert_response :success
    assert_match /text\/csv/, response.content_type
    assert_match /property_listing_template_\d{8}\.csv/, response.headers["Content-Disposition"]

    # Verify CSV structure - template is dynamically generated from Property.column_names
    csv = CSV.parse(response.body, headers: true)
    assert csv.headers.include?("title"), "CSV should have title column"
    assert csv.headers.include?("description"), "CSV should have description column"
    assert csv.headers.include?("address"), "CSV should have address column"
    assert csv.headers.include?("price"), "CSV should have price column"

    # Verify example row exists
    assert_equal 1, csv.size
  end

  test "should redirect tenant trying to download template" do
    post login_path, params: { email: @tenant.email, password: "password123" }
    get template_batch_properties_path(format: :csv)

    assert_redirected_to properties_path
    assert_match /landlord/i, flash[:alert]
  end

  test "should redirect unauthenticated user trying to download template" do
    get template_batch_properties_path(format: :csv)

    assert_redirected_to login_path
  end

  # Index Tests
  test "should access batch properties index for landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get batch_properties_path

    assert_response :success
  end

  test "should show upload history in index" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    # Create some upload history
    upload1 = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "properties_batch_1.csv",
      status: "completed",
      total_items: 10,
      successful_items: 9,
      failed_items: 1
    )

    upload2 = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "properties_batch_2.csv",
      status: "processing",
      total_items: 5,
      successful_items: 0,
      failed_items: 0
    )

    get batch_properties_path

    assert_response :success
  end

  test "should redirect tenant from batch properties index" do
    post login_path, params: { email: @tenant.email, password: "password123" }
    get batch_properties_path

    assert_redirected_to properties_path
    assert_match /landlord/i, flash[:alert]
  end

  # New Upload Tests
  test "should show new upload form for landlord" do
    post login_path, params: { email: @landlord.email, password: "password123" }
    get new_batch_property_path

    assert_response :success
  end

  # Upload Tests (JSON API)
  test "should create batch upload with valid CSV file via upload endpoint" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    valid_csv_content = <<~CSV
      title,description,address,city,price,bedrooms,bathrooms,square_feet,property_type
      "Modern Downtown Condo","Luxury 2BR condo","123 Main St","San Francisco",3500,2,2,1200,apartment
    CSV

    csv_file = Rack::Test::UploadedFile.new(
      StringIO.new(valid_csv_content),
      "text/csv",
      original_filename: "properties.csv"
    )

    assert_difference "BatchPropertyUpload.count", 1 do
      post upload_batch_properties_path, params: { csv_file: csv_file }
    end

    assert_response :success

    upload = BatchPropertyUpload.last
    assert_equal @landlord, upload.user
    assert_equal "properties.csv", upload.filename
  end

  test "should reject upload without CSV file" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    assert_no_difference "BatchPropertyUpload.count" do
      post upload_batch_properties_path, params: { csv_file: nil }
    end

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  # Show/Status Tests
  test "should show batch upload status for owner" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "processing",
      total_items: 10,
      successful_items: 5,
      failed_items: 0
    )

    get batch_property_path(upload)

    assert_response :success
  end

  test "should show batch upload status as JSON" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "processing",
      total_items: 10,
      successful_items: 5,
      failed_items: 0
    )

    # Use the status endpoint which is designed for JSON/AJAX polling
    # Session cookies are maintained in integration tests after login
    get status_batch_property_path(upload)

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal upload.id, json["batch_upload"]["id"]
    assert_equal "processing", json["batch_upload"]["status"]
  end

  test "should not show other user's batch upload" do
    other_landlord = create(:user, :landlord, :verified, email: "other@example.com")

    upload = BatchPropertyUpload.create!(
      user: other_landlord,
      filename: "private.csv",
      status: "completed"
    )

    post login_path, params: { email: @landlord.email, password: "password123" }

    # ErrorHandler rescues RecordNotFound and redirects for HTML format
    get batch_property_path(upload)
    assert_response :redirect
  end

  # Retry Failed Items Tests
  test "should retry failed batch items" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "completed",
      total_items: 10,
      successful_items: 8,
      failed_items: 2
    )

    # Create failed items
    2.times do |i|
      BatchPropertyItem.create!(
        batch_property_upload: upload,
        row_number: i + 1,
        status: "failed",
        error_message: "Invalid data",
        property_data: { title: "Failed Property #{i}" }.to_json
      )
    end

    post retry_failed_batch_property_path(upload)

    assert_response :success
    json = JSON.parse(response.body)
    assert json["message"].present?
  end

  # Download Results Tests
  test "should download results CSV" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "completed",
      total_items: 2,
      successful_items: 1,
      failed_items: 1
    )

    # Create result items
    BatchPropertyItem.create!(
      batch_property_upload: upload,
      row_number: 1,
      status: "completed",
      property_id: @property.id,
      property_data: { title: "Success Property" }.to_json
    )

    BatchPropertyItem.create!(
      batch_property_upload: upload,
      row_number: 2,
      status: "failed",
      error_message: "Price must be positive",
      property_data: { title: "Failed Property", price: -100 }.to_json
    )

    get results_batch_property_path(upload, format: :csv)

    assert_response :success
    assert_match /text\/csv/, response.content_type

    csv = CSV.parse(response.body, headers: true)
    assert_equal 2, csv.size
    assert_equal "completed", csv[0]["Status"]
    assert_equal "failed", csv[1]["Status"]
  end

  # Status Endpoint Tests
  test "should get batch upload status via status endpoint" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "processing",
      total_items: 100,
      processed_items: 50
    )

    get status_batch_property_path(upload)

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal upload.id, json["batch_upload"]["id"]
    assert json["progress"].present?
  end

  # Destroy Tests
  test "should delete batch upload when not processing" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "completed"
    )

    assert_difference "BatchPropertyUpload.count", -1 do
      delete batch_property_path(upload)
    end

    assert_response :success
  end

  test "should not delete batch upload while processing" do
    post login_path, params: { email: @landlord.email, password: "password123" }

    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "processing"
    )

    assert_no_difference "BatchPropertyUpload.count" do
      delete batch_property_path(upload)
    end

    assert_response :unprocessable_entity
  end

  # Model Behavior Tests
  test "should calculate progress percentage correctly" do
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "processing",
      total_items: 100,
      processed_items: 55
    )

    assert_equal 55.0, upload.progress_percentage
  end

  test "should return 100 for completed upload" do
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "completed",
      total_items: 100,
      processed_items: 100
    )

    assert_equal 100, upload.progress_percentage
  end

  test "should return 0 when total_items is zero" do
    upload = BatchPropertyUpload.create!(
      user: @landlord,
      filename: "test.csv",
      status: "pending",
      total_items: 0
    )

    assert_equal 0, upload.progress_percentage
  end

  private

  def sign_in_as(user)
    post login_path, params: { email: user.email, password: "password123" }
  end
end
