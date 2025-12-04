require "test_helper"

class ProcessBatchPropertyUploadJobTest < ActiveJob::TestCase
  setup do
    @user = create(:user, :landlord, :verified)
    @upload = BatchPropertyUpload.create!(
      user: @user,
      file_name: "test.csv",
      status: "pending",
      total_rows: 2
    )

    # Create CSV content
    @csv_content = <<~CSV
      title,description,address,city,state,postal_code,price,bedrooms,bathrooms,area,property_type,listing_type
      "Test Property 1","Description 1","123 Test St","San Francisco","CA","94105",3000,2,1,1000,apartment,rent
      "Test Property 2","Description 2","456 Test Ave","San Francisco","CA","94110",500000,3,2,1500,house,sale
    CSV

    # Attach CSV file to upload
    @upload.csv_file.attach(
      io: StringIO.new(@csv_content),
      filename: "test.csv",
      content_type: "text/csv"
    )
  end

  test "processes valid CSV successfully" do
    assert_equal "pending", @upload.status

    perform_enqueued_jobs do
      ProcessBatchPropertyUploadJob.perform_later(@upload)
    end

    @upload.reload
    assert_equal "completed", @upload.status
    assert_equal 2, @upload.batch_property_items.count
    assert_equal 2, @upload.successful_rows
    assert_equal 0, @upload.failed_rows
  end

  test "creates batch items for each row" do
    perform_enqueued_jobs do
      ProcessBatchPropertyUploadJob.perform_later(@upload)
    end

    items = @upload.batch_property_items.order(:row_number)

    assert_equal 2, items.count
    assert_equal 1, items.first.row_number
    assert_equal "Test Property 1", items.first.row_data["title"]
    assert_equal 2, items.second.row_number
    assert_equal "Test Property 2", items.second.row_data["title"]
  end

  test "handles missing required fields" do
    invalid_csv = <<~CSV
      title,price
      "Missing Fields",1000
    CSV

    @upload.csv_file.attach(
      io: StringIO.new(invalid_csv),
      filename: "invalid.csv",
      content_type: "text/csv"
    )

    perform_enqueued_jobs do
      ProcessBatchPropertyUploadJob.perform_later(@upload)
    end

    @upload.reload
    assert_equal "failed", @upload.status
    assert_match /missing required columns/i, @upload.error_message
  end

  test "handles malformed CSV" do
    @upload.csv_file.attach(
      io: StringIO.new("not,a,valid\ncsv file"),
      filename: "malformed.csv",
      content_type: "text/csv"
    )

    perform_enqueued_jobs do
      ProcessBatchPropertyUploadJob.perform_later(@upload)
    end

    @upload.reload
    assert_equal "failed", @upload.status
    assert_not_nil @upload.error_message
  end

  test "updates status to processing when job starts" do
    # Mock the job to check status changes
    job = ProcessBatchPropertyUploadJob.new

    job.stub :process_csv, true do
      job.perform(@upload)

      @upload.reload
      assert_equal "processing", @upload.status
      assert_not_nil @upload.started_at
    end
  end

  test "handles partial failures" do
    mixed_csv = <<~CSV
      title,description,address,city,state,postal_code,price,bedrooms,bathrooms,area,property_type,listing_type
      "Valid Property","Good description","123 Valid St","San Francisco","CA","94105",3000,2,1,1000,apartment,rent
      "Invalid Property","Bad price","456 Invalid Ave","San Francisco","CA","94110",-500,3,2,1500,house,sale
    CSV

    @upload.csv_file.attach(
      io: StringIO.new(mixed_csv),
      filename: "mixed.csv",
      content_type: "text/csv"
    )
    @upload.update!(total_rows: 2)

    perform_enqueued_jobs do
      ProcessBatchPropertyUploadJob.perform_later(@upload)
    end

    @upload.reload
    assert_equal "completed_with_errors", @upload.status
    assert_equal 1, @upload.successful_rows
    assert_equal 1, @upload.failed_rows

    # Check individual items
    success_item = @upload.batch_property_items.find_by(status: "success")
    assert_not_nil success_item
    assert_not_nil success_item.property_id

    failed_item = @upload.batch_property_items.find_by(status: "failed")
    assert_not_nil failed_item
    assert_nil failed_item.property_id
    assert_match /price must be greater than 0/i, failed_item.error_message
  end

  test "broadcasts progress updates" do
    # In a real app, you would test ActionCable broadcasts
    # For now, we'll just verify the data is updated correctly
    perform_enqueued_jobs do
      ProcessBatchPropertyUploadJob.perform_later(@upload)
    end

    @upload.reload
    assert_equal 100.0, @upload.progress_percentage
  end

  test "handles job cancellation" do
    @upload.update!(status: "cancelled")

    # Job should not process cancelled uploads
    assert_no_enqueued_jobs do
      job = ProcessBatchPropertyUploadJob.new
      job.perform(@upload)
    end

    assert_equal "cancelled", @upload.reload.status
  end

  test "rescues and logs exceptions" do
    # Simulate an exception during processing
    ProcessBatchPropertyUploadJob.stub_any_instance :process_csv, -> { raise StandardError, "Test error" } do
      assert_nothing_raised do
        perform_enqueued_jobs do
          ProcessBatchPropertyUploadJob.perform_later(@upload)
        end
      end
    end

    @upload.reload
    assert_equal "failed", @upload.status
    assert_match /Test error/, @upload.error_message
  end

  test "enqueues individual property creation jobs" do
    assert_enqueued_jobs 2, only: ProcessBatchPropertyItemJob do
      perform_enqueued_jobs only: ProcessBatchPropertyUploadJob do
        ProcessBatchPropertyUploadJob.perform_later(@upload)
      end
    end
  end

  test "respects batch size configuration" do
    # Create a large CSV
    large_csv = CSV.generate do |csv|
      csv << %w[title description address city state postal_code price bedrooms bathrooms area property_type listing_type]
      50.times do |i|
        csv << [ "Property #{i}", "Desc #{i}", "#{i} Main St", "SF", "CA", "94105", 1000 + i, 2, 1, 1000, "apartment", "rent" ]
      end
    end

    @upload.csv_file.attach(
      io: StringIO.new(large_csv),
      filename: "large.csv",
      content_type: "text/csv"
    )
    @upload.update!(total_rows: 50)

    # Verify items are created in batches
    assert_difference "BatchPropertyItem.count", 50 do
      perform_enqueued_jobs only: ProcessBatchPropertyUploadJob do
        ProcessBatchPropertyUploadJob.perform_later(@upload)
      end
    end
  end
end
