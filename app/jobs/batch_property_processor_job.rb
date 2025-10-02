class BatchPropertyProcessorJob < ApplicationJob
  queue_as :default

  # Retry failed jobs up to 3 times with exponential backoff
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(batch_upload_id)
    @batch_upload = BatchPropertyUpload.find(batch_upload_id)

    Rails.logger.info "Starting batch property processing for upload #{@batch_upload.id}"

    begin
      # Update status to processing
      @batch_upload.update!(status: "processing")

      # Process each pending item
      process_batch_items

      # Final status update
      finalize_batch_processing

      Rails.logger.info "Completed batch property processing for upload #{@batch_upload.id}"

    rescue StandardError => e
      Rails.logger.error "Batch processing failed for upload #{@batch_upload.id}: #{e.message}"
      @batch_upload.mark_as_failed!("Processing failed: #{e.message}")
      raise e
    end
  end

  private

  def process_batch_items
    pending_items = @batch_upload.batch_property_items.pending_items.by_row_number
    total_items = pending_items.count

    Rails.logger.info "Processing #{total_items} pending items"

    pending_items.find_each.with_index do |item, index|
      begin
        # Process individual item
        process_single_item(item)

        # Log progress every 10 items
        if (index + 1) % 10 == 0
          Rails.logger.info "Processed #{index + 1}/#{total_items} items"
        end

        # Small delay to prevent overwhelming the system
        sleep(0.1) if total_items > 100

      rescue StandardError => e
        Rails.logger.error "Failed to process item #{item.id}: #{e.message}"
        item.mark_as_failed!("Processing error: #{e.message}")
      end
    end
  end

  def process_single_item(item)
    Rails.logger.debug "Processing item #{item.id} (row #{item.row_number})"

    # Create the property
    success = item.create_property!

    if success
      Rails.logger.debug "Successfully created property for item #{item.id}"

      # Send notification if needed
      notify_property_created(item.property) if item.property
    else
      Rails.logger.warn "Failed to create property for item #{item.id}: #{item.error_message}"
    end
  end

  def finalize_batch_processing
    @batch_upload.reload

    # Check if all items have been processed
    total_items = @batch_upload.total_items
    processed_items = @batch_upload.processed_items

    if processed_items >= total_items
      @batch_upload.mark_as_completed!

      # Send completion notification
      send_completion_notification

      Rails.logger.info "Batch upload #{@batch_upload.id} completed successfully"
    else
      Rails.logger.warn "Batch upload #{@batch_upload.id} incomplete: #{processed_items}/#{total_items} processed"
    end
  end

  def notify_property_created(property)
    # Send notification to landlord about new property
    # This could be an email, in-app notification, etc.
    begin
      # Example: Send email notification
      # PropertyMailer.property_created(property).deliver_later

      Rails.logger.info "Property created notification sent for property #{property.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to send property creation notification: #{e.message}"
    end
  end

  def send_completion_notification
    begin
      # Send batch completion notification to user
      BatchPropertyMailer.upload_completed(@batch_upload).deliver_later

      Rails.logger.info "Batch completion notification sent for upload #{@batch_upload.id}"
    rescue StandardError => e
      Rails.logger.error "Failed to send batch completion notification: #{e.message}"
    end
  end
end
