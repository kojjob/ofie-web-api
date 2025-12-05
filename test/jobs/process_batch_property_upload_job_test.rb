require "test_helper"

class ProcessBatchPropertyUploadJobTest < ActiveJob::TestCase
  setup do
    @user = create(:user, :landlord, :verified)
    @upload = BatchPropertyUpload.create!(
      user: @user,
      filename: "test.csv",
      status: "pending",
      total_items: 2
    )
  end

  test "batch upload is created with valid attributes" do
    assert @upload.valid?
    assert_equal "test.csv", @upload.filename
    assert_equal "pending", @upload.status
    assert_equal 2, @upload.total_items
  end

  test "batch upload belongs to user" do
    assert_equal @user, @upload.user
    assert @upload.user.landlord?
  end

  test "batch upload has correct initial state" do
    assert @upload.pending?
    assert_equal 0, @upload.processed_items
    assert_equal 0, @upload.successful_items
    assert_equal 0, @upload.failed_items
  end

  test "batch upload can track progress" do
    @upload.update!(processed_items: 1, successful_items: 1)
    assert_equal 50.0, @upload.progress_percentage

    @upload.update!(processed_items: 2, successful_items: 2)
    assert_equal 100.0, @upload.progress_percentage
  end

  test "batch upload can be marked as completed" do
    @upload.mark_as_completed!
    assert @upload.completed?
    assert_not_nil @upload.completed_at
  end

  test "batch upload can be marked as failed" do
    @upload.mark_as_failed!("Test error message")
    assert @upload.failed?
    assert_equal "Test error message", @upload.error_message
    assert_not_nil @upload.completed_at
  end

  test "batch upload can increment counters" do
    @upload.increment_processed!
    assert_equal 1, @upload.reload.processed_items

    @upload.increment_successful!
    assert_equal 1, @upload.reload.successful_items

    @upload.increment_failed!
    assert_equal 1, @upload.reload.failed_items
  end

  test "batch upload calculates success rate" do
    @upload.update!(total_items: 10, successful_items: 8)
    assert_equal 80.0, @upload.success_rate
  end

  test "batch processor job processes batch upload" do
    # Update status to processing
    @upload.update!(status: "processing")
    assert @upload.processing?

    # Simulate batch processing completion
    @upload.update!(
      status: "completed",
      processed_items: 2,
      successful_items: 2,
      completed_at: Time.current
    )

    assert @upload.completed?
    assert_equal 2, @upload.successful_items
    assert_equal 0, @upload.failed_items
  end

  test "batch upload handles partial failures" do
    @upload.update!(
      status: "completed",
      total_items: 10,
      processed_items: 10,
      successful_items: 8,
      failed_items: 2
    )

    assert @upload.completed_with_errors?
    assert_equal 80.0, @upload.success_rate
    assert @upload.has_errors?
  end

  test "batch upload summary includes all statistics" do
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

  test "batch processor job can be enqueued" do
    assert_enqueued_with(job: BatchPropertyProcessorJob, args: [@upload.id]) do
      BatchPropertyProcessorJob.perform_later(@upload.id)
    end
  end
end
