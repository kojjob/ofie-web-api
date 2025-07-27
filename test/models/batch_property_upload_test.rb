require "test_helper"

class BatchPropertyUploadTest < ActiveSupport::TestCase
  setup do
    @user = users(:landlord)
    @upload = BatchPropertyUpload.new(
      user: @user,
      file_name: "properties.csv",
      status: "pending",
      total_rows: 10
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

  test "requires file_name" do
    @upload.file_name = nil
    assert_not @upload.valid?
    assert_includes @upload.errors[:file_name], "can't be blank"
  end

  test "requires valid status" do
    @upload.status = "invalid_status"
    assert_not @upload.valid?
    assert_includes @upload.errors[:status], "is not included in the list"
  end

  test "valid statuses" do
    valid_statuses = %w[pending processing completed completed_with_errors failed cancelled]
    
    valid_statuses.each do |status|
      @upload.status = status
      assert @upload.valid?, "#{status} should be a valid status"
    end
  end

  test "calculates processed rows correctly" do
    @upload.successful_rows = 7
    @upload.failed_rows = 2
    assert_equal 9, @upload.processed_rows
  end

  test "calculates progress percentage correctly" do
    @upload.total_rows = 100
    @upload.successful_rows = 60
    @upload.failed_rows = 10
    assert_equal 70.0, @upload.progress_percentage
  end

  test "handles zero total rows for progress" do
    @upload.total_rows = 0
    assert_equal 0.0, @upload.progress_percentage
  end

  test "completed? method" do
    @upload.status = "completed"
    assert @upload.completed?
    
    @upload.status = "completed_with_errors"
    assert @upload.completed?
    
    @upload.status = "processing"
    assert_not @upload.completed?
  end

  test "processing? method" do
    @upload.status = "processing"
    assert @upload.processing?
    
    @upload.status = "completed"
    assert_not @upload.processing?
  end

  test "has_errors? method" do
    @upload.status = "completed_with_errors"
    assert @upload.has_errors?
    
    @upload.status = "failed"
    assert @upload.has_errors?
    
    @upload.status = "completed"
    assert_not @upload.has_errors?
  end

  test "can_retry? method" do
    @upload.status = "completed_with_errors"
    assert @upload.can_retry?
    
    @upload.status = "failed"
    assert @upload.can_retry?
    
    @upload.status = "processing"
    assert_not @upload.can_retry?
  end

  test "creates associated batch items" do
    @upload.save!
    
    assert_difference "BatchPropertyItem.count", 3 do
      3.times do |i|
        @upload.batch_property_items.create!(
          row_number: i + 1,
          status: "pending",
          row_data: { title: "Property #{i}" }
        )
      end
    end
    
    assert_equal 3, @upload.batch_property_items.count
  end

  test "destroys associated items when deleted" do
    @upload.save!
    @upload.batch_property_items.create!(
      row_number: 1,
      status: "success",
      row_data: { title: "Test Property" }
    )
    
    assert_difference "BatchPropertyItem.count", -1 do
      @upload.destroy
    end
  end

  test "scopes for different statuses" do
    # Create uploads with different statuses
    pending = BatchPropertyUpload.create!(user: @user, file_name: "pending.csv", status: "pending")
    processing = BatchPropertyUpload.create!(user: @user, file_name: "processing.csv", status: "processing")
    completed = BatchPropertyUpload.create!(user: @user, file_name: "completed.csv", status: "completed")
    failed = BatchPropertyUpload.create!(user: @user, file_name: "failed.csv", status: "failed")
    
    assert_includes BatchPropertyUpload.pending, pending
    assert_includes BatchPropertyUpload.processing, processing
    assert_includes BatchPropertyUpload.completed, completed
    assert_includes BatchPropertyUpload.failed, failed
  end

  test "recent scope orders by created_at desc" do
    old_upload = BatchPropertyUpload.create!(
      user: @user,
      file_name: "old.csv",
      status: "completed",
      created_at: 2.days.ago
    )
    
    new_upload = BatchPropertyUpload.create!(
      user: @user,
      file_name: "new.csv",
      status: "completed",
      created_at: 1.hour.ago
    )
    
    recent = BatchPropertyUpload.recent
    assert_equal new_upload, recent.first
    assert_equal old_upload, recent.last
  end

  test "updates timestamps on status change" do
    @upload.save!
    
    # Test started_at
    assert_nil @upload.started_at
    @upload.update!(status: "processing")
    assert_not_nil @upload.started_at
    
    # Test completed_at
    assert_nil @upload.completed_at
    @upload.update!(status: "completed")
    assert_not_nil @upload.completed_at
  end

  test "calculates duration correctly" do
    @upload.save!
    @upload.update!(
      status: "processing",
      started_at: 2.hours.ago
    )
    @upload.update!(
      status: "completed",
      completed_at: 1.hour.ago
    )
    
    assert_equal 3600, @upload.duration_in_seconds
    assert_equal "01:00:00", @upload.formatted_duration
  end

  test "generates summary statistics" do
    @upload.save!
    @upload.update!(
      total_rows: 100,
      successful_rows: 85,
      failed_rows: 15,
      status: "completed_with_errors"
    )
    
    summary = @upload.summary
    assert_equal 100, summary[:total]
    assert_equal 85, summary[:successful]
    assert_equal 15, summary[:failed]
    assert_equal 85.0, summary[:success_rate]
    assert_equal "completed_with_errors", summary[:status]
  end
end