require "test_helper"

class BatchPropertyUploadTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :landlord)
    @upload = BatchPropertyUpload.new(
      user: @user,
      filename: "properties.csv",
      status: "pending",
      total_items: 10
    )
  end

  test "valid batch upload" do
    assert @upload.valid?
  end

  test "requires user" do
    @upload.user = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:user], "must exist"
  end

  test "requires filename" do
    @upload.filename = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:filename], "can't be blank"
  end

  test "requires valid status" do
    # Rails enum raises ArgumentError when assigning invalid status values
    # Test that only valid statuses are accepted
    assert_raises(ArgumentError) do
      @upload.status = "invalid_status"
    end
  end

  test "valid statuses" do
    valid_statuses = %w[pending processing validated completed failed cancelled]

    valid_statuses.each do |status|
      @upload.status = status
      assert @upload.valid?, "#{status} should be a valid status"
    end
  end

  test "calculates progress percentage correctly" do
    @upload.total_items = 100
    @upload.processed_items = 70
    assert_equal 70.0, @upload.progress_percentage
  end

  test "handles zero total items for progress" do
    @upload.total_items = 0
    assert_equal 0.0, @upload.progress_percentage
  end

  test "handles nil total items for progress" do
    @upload.total_items = nil
    assert_equal 0, @upload.progress_percentage
  end

  test "completed? method returns true for completed status" do
    @upload.status = "completed"
    assert @upload.completed?
  end

  test "completed? method returns false for non-completed status" do
    @upload.status = "processing"
    assert_not @upload.completed?
  end

  test "processing? method" do
    @upload.status = "processing"
    assert @upload.processing?

    @upload.status = "completed"
    assert_not @upload.processing?
  end

  test "has_errors? method returns true for failed status" do
    @upload.status = "failed"
    assert @upload.has_errors?
  end

  test "has_errors? method returns true when failed_items > 0" do
    @upload.status = "completed"
    @upload.failed_items = 5
    assert @upload.has_errors?
  end

  test "has_errors? method returns false for completed without errors" do
    @upload.status = "completed"
    @upload.failed_items = 0
    assert_not @upload.has_errors?
  end

  test "can_be_cancelled? returns true for pending status" do
    @upload.status = "pending"
    assert @upload.can_be_cancelled?
  end

  test "can_be_cancelled? returns true for processing status" do
    @upload.status = "processing"
    assert @upload.can_be_cancelled?
  end

  test "can_be_cancelled? returns true for validated status" do
    @upload.status = "validated"
    assert @upload.can_be_cancelled?
  end

  test "can_be_cancelled? returns false for completed status" do
    @upload.status = "completed"
    assert_not @upload.can_be_cancelled?
  end

  test "creates associated batch items" do
    @upload.save!

    assert_difference "BatchPropertyItem.count", 3 do
      3.times do |i|
        @upload.batch_property_items.create!(
          row_number: i + 1,
          status: "pending",
          property_data: { title: "Property #{i}" }.to_json
        )
      end
    end

    assert_equal 3, @upload.batch_property_items.count
  end

  test "destroys associated items when deleted" do
    @upload.save!
    @upload.batch_property_items.create!(
      row_number: 1,
      status: "completed",
      property_data: { title: "Test Property" }.to_json
    )

    assert_difference "BatchPropertyItem.count", -1 do
      @upload.destroy
    end
  end

  test "scopes for different statuses" do
    # Create uploads with different statuses
    pending_upload = BatchPropertyUpload.create!(user: @user, filename: "pending.csv", status: "pending")
    processing_upload = BatchPropertyUpload.create!(user: @user, filename: "processing.csv", status: "processing")
    completed_upload = BatchPropertyUpload.create!(user: @user, filename: "completed.csv", status: "completed")
    failed_upload = BatchPropertyUpload.create!(user: @user, filename: "failed.csv", status: "failed")

    assert_includes BatchPropertyUpload.pending, pending_upload
    assert_includes BatchPropertyUpload.processing, processing_upload
    assert_includes BatchPropertyUpload.completed, completed_upload
    assert_includes BatchPropertyUpload.failed, failed_upload
  end

  test "recent scope orders by created_at desc" do
    old_upload = BatchPropertyUpload.create!(
      user: @user,
      filename: "old.csv",
      status: "completed",
      created_at: 2.days.ago
    )

    new_upload = BatchPropertyUpload.create!(
      user: @user,
      filename: "new.csv",
      status: "completed",
      created_at: 1.hour.ago
    )

    recent = BatchPropertyUpload.recent
    assert_equal new_upload, recent.first
    assert_equal old_upload, recent.last
  end

  test "updates completed_at on status change to completed" do
    @upload.save!
    assert_nil @upload.completed_at

    @upload.update!(status: "completed")
    assert_not_nil @upload.completed_at
  end

  test "updates completed_at on status change to failed" do
    @upload.save!
    assert_nil @upload.completed_at

    @upload.update!(status: "failed")
    assert_not_nil @upload.completed_at
  end

  test "calculates success rate correctly" do
    @upload.save!
    @upload.update!(
      total_items: 100,
      successful_items: 85
    )

    assert_equal 85.0, @upload.success_rate
  end

  test "generates summary statistics" do
    @upload.save!
    @upload.update!(
      total_items: 100,
      valid_items: 90,
      invalid_items: 10,
      processed_items: 90,
      successful_items: 85,
      failed_items: 5,
      status: "completed"
    )

    summary = @upload.summary
    assert_equal 100, summary[:total]
    assert_equal 90, summary[:valid]
    assert_equal 10, summary[:invalid]
    assert_equal 90, summary[:processed]
    assert_equal 85, summary[:successful]
    assert_equal 5, summary[:failed]
  end

  test "mark_as_completed! updates status and completed_at" do
    @upload.save!
    @upload.update!(total_items: 10)

    @upload.mark_as_completed!

    assert @upload.completed?
    assert_not_nil @upload.completed_at
    assert_equal 10, @upload.processed_items
  end

  test "mark_as_failed! updates status and error_message" do
    @upload.save!

    @upload.mark_as_failed!("Test error message")

    assert @upload.failed?
    assert_equal "Test error message", @upload.error_message
    assert_not_nil @upload.completed_at
  end

  test "increment_processed! increments processed_items" do
    @upload.save!
    @upload.update!(processed_items: 5, total_items: 10)

    @upload.increment_processed!
    @upload.reload

    assert_equal 6, @upload.processed_items
  end

  test "increment_successful! increments successful_items" do
    @upload.save!
    @upload.update!(successful_items: 5)

    @upload.increment_successful!
    @upload.reload

    assert_equal 6, @upload.successful_items
  end

  test "increment_failed! increments failed_items" do
    @upload.save!
    @upload.update!(failed_items: 2)

    @upload.increment_failed!
    @upload.reload

    assert_equal 3, @upload.failed_items
  end

  test "all_items_processed? returns true when processed equals total" do
    @upload.save!
    @upload.update!(total_items: 10, processed_items: 10)

    assert @upload.all_items_processed?
  end

  test "all_items_processed? returns false when processed less than total" do
    @upload.save!
    @upload.update!(total_items: 10, processed_items: 5)

    assert_not @upload.all_items_processed?
  end

  test "completed_with_errors? returns true for completed with failed items" do
    @upload.save!
    @upload.update!(status: "completed", failed_items: 5)

    assert @upload.completed_with_errors?
  end

  test "completed_with_errors? returns false for completed without failed items" do
    @upload.save!
    @upload.update!(status: "completed", failed_items: 0)

    assert_not @upload.completed_with_errors?
  end

  test "can_be_processed? returns true for validated with valid items" do
    @upload.save!
    @upload.update!(status: "validated", valid_items: 5)

    assert @upload.can_be_processed?
  end

  test "can_be_processed? returns false for non-validated status" do
    @upload.save!
    @upload.update!(status: "pending", valid_items: 5)

    assert_not @upload.can_be_processed?
  end

  test "sets default values on create" do
    upload = BatchPropertyUpload.create!(user: @user, filename: "test.csv")

    assert_equal "pending", upload.status
    assert_equal 0, upload.total_items
    assert_equal 0, upload.valid_items
    assert_equal 0, upload.invalid_items
    assert_equal 0, upload.processed_items
    assert_equal 0, upload.successful_items
    assert_equal 0, upload.failed_items
  end
end
