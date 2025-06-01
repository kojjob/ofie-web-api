class BatchPropertiesController < ApplicationController
  before_action :authenticate_web_request
  before_action :authorize_landlord

  # GET /batch_properties
  def index
    @recent_uploads = current_user.batch_property_uploads
                                 .includes(:batch_property_items)
                                 .order(created_at: :desc)
                                 .limit(10)
  end

  # GET /batch_properties/new
  def new
    # Show the batch upload interface
  end

  # GET /batch_properties/template
  def template
    respond_to do |format|
      format.csv do
        begin
          csv_data = generate_csv_template
          send_data csv_data,
                    filename: "property_listing_template_#{Date.current.strftime('%Y%m%d')}.csv",
                    type: "text/csv",
                    disposition: "attachment"
        rescue StandardError => e
          Rails.logger.error "CSV template generation failed: #{e.message}"
          redirect_to batch_properties_path, alert: "Failed to generate CSV template. Please try again."
        end
      end
      format.html do
        # If someone tries to access template without .csv format, redirect to batch properties
        redirect_to batch_properties_path, notice: "Please use the 'Download Template' button to get the CSV template."
      end
    end
  end

  # POST /batch_properties/upload
  def upload
    unless params[:csv_file].present?
      render json: { error: "Please select a CSV file to upload" }, status: :unprocessable_entity
      return
    end

    begin
      # Create batch upload record
      @batch_upload = current_user.batch_property_uploads.create!(
        filename: params[:csv_file].original_filename,
        status: "processing"
      )

      # Process CSV file
      csv_data = params[:csv_file].read
      properties_data = parse_csv_data(csv_data)

      # Validate and create batch items
      validation_results = validate_properties_data(properties_data)

      if validation_results[:valid_count] > 0
        create_batch_items(validation_results[:valid_properties])
        @batch_upload.update!(
          status: "validated",
          total_items: validation_results[:total_count],
          valid_items: validation_results[:valid_count],
          invalid_items: validation_results[:invalid_count]
        )

        render json: {
          message: "CSV uploaded and validated successfully",
          batch_upload: batch_upload_json(@batch_upload),
          validation_summary: validation_results[:summary]
        }
      else
        @batch_upload.update!(status: "failed", error_message: "No valid properties found")
        render json: {
          error: "No valid properties found in CSV",
          validation_errors: validation_results[:errors]
        }, status: :unprocessable_entity
      end

    rescue CSV::MalformedCSVError => e
      @batch_upload&.update!(status: "failed", error_message: "Invalid CSV format: #{e.message}")
      render json: { error: "Invalid CSV format: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      @batch_upload&.update!(status: "failed", error_message: e.message)
      render json: { error: "Upload failed: #{e.message}" }, status: :internal_server_error
    end
  end

  # GET /batch_properties/progress (for real-time updates)
  def progress
    @recent_uploads = current_user.batch_property_uploads
                                 .includes(:batch_property_items)
                                 .order(created_at: :desc)
                                 .limit(10)

    # Check for active uploads
    active_uploads = @recent_uploads.where(status: ['processing', 'validated'])
    has_active_uploads = active_uploads.any?

    # Prepare upload data for updates
    uploads_data = active_uploads.map do |upload|
      {
        id: upload.id,
        status: upload.status,
        status_html: render_to_string('batch_properties/status_badge_enhanced', locals: { upload: upload }, layout: false),
        progress_percentage: upload.progress_percentage,
        successful_items: upload.successful_items || 0,
        failed_items: upload.failed_items || 0,
        processed_items: upload.processed_items || 0
      }
    end

    # Prepare processing queue data
    processing_queue = {
      items: active_uploads.limit(3).map do |upload|
        {
          id: upload.id,
          filename: upload.filename,
          progress_percentage: upload.progress_percentage,
          total_items: upload.total_items,
          created_at: upload.created_at
        }
      end
    }

    render json: {
      has_active_uploads: has_active_uploads,
      stats: {
        total_uploads: @recent_uploads.count,
        properties_created: @recent_uploads.sum(:successful_items),
        processing: @recent_uploads.where(status: ['processing', 'validated']).count,
        failed_items: @recent_uploads.sum(:failed_items)
      },
      uploads: uploads_data,
      processing_queue: processing_queue,
      timestamp: Time.current.iso8601
    }
  end

  # GET /batch_properties/:id/preview
  def preview
    @batch_upload = current_user.batch_property_uploads.find(params[:id])
    @batch_items = @batch_upload.batch_property_items
                                .includes(:property)
                                .order(:row_number)
                                .page(params[:page])
                                .per(20)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          batch_upload: batch_upload_json(@batch_upload),
          items: @batch_items.map { |item| batch_item_json(item) },
          pagination: {
            current_page: @batch_items.current_page,
            total_pages: @batch_items.total_pages,
            total_count: @batch_items.total_count
          }
        }
      end
    end
  end

  # POST /batch_properties/:id/process
  def process_batch
    @batch_upload = current_user.batch_property_uploads.find(params[:id])

    Rails.logger.info "Processing batch #{@batch_upload.id} for user #{current_user.id}"
    Rails.logger.debug "Batch upload details: status=#{@batch_upload.status}, total_items=#{@batch_upload.total_items}, valid_items=#{@batch_upload.valid_items}, invalid_items=#{@batch_upload.invalid_items}"

    # Check batch upload status
    unless @batch_upload.validated?
      Rails.logger.warn "Batch upload #{@batch_upload.id} is not validated. Current status: #{@batch_upload.status}"

      render json: {
        error: "Batch upload must be validated before processing",
        current_status: @batch_upload.status,
        required_status: "validated",
        debug_info: {
          id: @batch_upload.id,
          status: @batch_upload.status,
          total_items: @batch_upload.total_items,
          valid_items: @batch_upload.valid_items,
          invalid_items: @batch_upload.invalid_items,
          pending_items_count: @batch_upload.batch_property_items.where(status: "pending").count,
          all_items_statuses: @batch_upload.batch_property_items.pluck(:status).tally
        }
      }, status: :unprocessable_entity
      return
    end

    # Check if there are valid items to process
    unless @batch_upload.valid_items && @batch_upload.valid_items > 0
      Rails.logger.warn "Batch upload #{@batch_upload.id} has no valid items. valid_items=#{@batch_upload.valid_items}"

      render json: {
        error: "No valid items to process",
        valid_items: @batch_upload.valid_items,
        debug_info: {
          total_items: @batch_upload.total_items,
          pending_items_count: @batch_upload.batch_property_items.where(status: "pending").count,
          all_items_statuses: @batch_upload.batch_property_items.pluck(:status).tally
        }
      }, status: :unprocessable_entity
      return
    end

    begin
      Rails.logger.info "Starting background job for batch #{@batch_upload.id}"

      # Process in background job
      BatchPropertyProcessorJob.perform_later(@batch_upload.id)

      @batch_upload.update!(status: "processing")

      Rails.logger.info "Successfully started processing for batch #{@batch_upload.id}"

      render json: {
        message: "Batch processing started",
        batch_upload: batch_upload_json(@batch_upload)
      }

    rescue StandardError => e
      Rails.logger.error "Failed to start batch processing for #{@batch_upload.id}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"

      render json: {
        error: "Failed to start batch processing: #{e.message}",
        debug_info: {
          batch_id: @batch_upload.id,
          status: @batch_upload.status
        }
      }, status: :unprocessable_entity
    end
  end

  # GET /batch_properties/:id/status
  def status
    @batch_upload = current_user.batch_property_uploads.find(params[:id])

    render json: {
      batch_upload: batch_upload_json(@batch_upload),
      progress: calculate_progress(@batch_upload)
    }
  end

  # POST /batch_properties/:id/fix_status
  def fix_status
    @batch_upload = current_user.batch_property_uploads.find(params[:id])

    Rails.logger.info "Fixing status for batch #{@batch_upload.id}"
    Rails.logger.debug "Current status: #{@batch_upload.status}, valid_items: #{@batch_upload.valid_items}"

    # Count pending items to determine if we should fix the status
    pending_items_count = @batch_upload.batch_property_items.where(status: "pending").count

    Rails.logger.debug "Pending items count: #{pending_items_count}"

    # Fix status if batch has pending items but wrong status or counters
    if pending_items_count > 0
      @batch_upload.update!(
        status: "validated",
        valid_items: pending_items_count,
        total_items: @batch_upload.batch_property_items.count,
        processed_items: @batch_upload.batch_property_items.where(status: ["completed", "failed"]).count,
        failed_items: @batch_upload.batch_property_items.where(status: "failed").count,
        successful_items: @batch_upload.batch_property_items.where(status: "completed").count
      )

      Rails.logger.info "Fixed batch #{@batch_upload.id} status and counters"

      render json: {
        message: "Batch upload status and counters fixed",
        batch_upload: batch_upload_json(@batch_upload),
        debug_info: {
          pending_items: pending_items_count,
          total_items: @batch_upload.total_items,
          valid_items: @batch_upload.valid_items
        }
      }
    else
      render json: {
        error: "Cannot fix status - no pending items found",
        current_status: @batch_upload.status,
        valid_items: @batch_upload.valid_items,
        debug_info: {
          pending_items: pending_items_count,
          all_items_statuses: @batch_upload.batch_property_items.pluck(:status).tally
        }
      }, status: :unprocessable_entity
    end
  end

  # POST /batch_properties/:id/retry_failed
  def retry_failed
    @batch_upload = current_user.batch_property_uploads.find(params[:id])

    # Get all items with failed status
    failed_items = @batch_upload.batch_property_items.where(status: "failed")

    Rails.logger.info "Retry failed items for batch #{@batch_upload.id}: found #{failed_items.count} failed items"
    Rails.logger.debug "Batch upload failed_items counter: #{@batch_upload.failed_items}"
    Rails.logger.debug "All batch items statuses: #{@batch_upload.batch_property_items.pluck(:status).tally}"

    if failed_items.empty?
      # Check if there are any items that might be in a different status but should be retryable
      all_items = @batch_upload.batch_property_items.includes(:property)
      items_with_errors = all_items.where.not(error_message: nil)

      Rails.logger.warn "No failed items found, but #{items_with_errors.count} items have error messages"

      render json: {
        error: "No failed items to retry",
        debug_info: {
          total_items: all_items.count,
          items_with_errors: items_with_errors.count,
          status_breakdown: all_items.pluck(:status).tally,
          batch_failed_counter: @batch_upload.failed_items
        }
      }, status: :unprocessable_entity
      return
    end

    begin
      # Reset failed items to pending
      retry_count = 0
      failed_items.each do |item|
        if item.retry_processing!
          retry_count += 1
          Rails.logger.debug "Successfully reset item #{item.id} to pending"
        else
          Rails.logger.warn "Failed to reset item #{item.id}: #{item.errors.full_messages.join(', ')}"
        end
      end

      # Update batch upload counters
      @batch_upload.reload
      @batch_upload.update!(
        status: "validated",
        failed_items: [@batch_upload.failed_items - retry_count, 0].max,
        processed_items: [@batch_upload.processed_items - retry_count, 0].max
      )

      Rails.logger.info "Successfully reset #{retry_count} failed items for batch #{@batch_upload.id}"

      render json: {
        message: "#{retry_count} failed items reset for retry",
        batch_upload: batch_upload_json(@batch_upload),
        debug_info: {
          items_reset: retry_count,
          total_failed_found: failed_items.count
        }
      }

    rescue StandardError => e
      Rails.logger.error "Error resetting failed items for batch #{@batch_upload.id}: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"

      render json: {
        error: "Failed to reset items: #{e.message}",
        debug_info: {
          batch_id: @batch_upload.id,
          failed_items_count: failed_items.count
        }
      }, status: :unprocessable_entity
    end
  end

  # GET /batch_properties/:id/item_details/:item_id
  def item_details
    @batch_upload = current_user.batch_property_uploads.find(params[:id])
    @batch_item = @batch_upload.batch_property_items.find(params[:item_id])

    render json: {
      id: @batch_item.id,
      row_number: @batch_item.row_number,
      status: @batch_item.status,
      property_data: @batch_item.property_data,
      property_id: @batch_item.property_id,
      error_message: @batch_item.error_message,
      created_at: @batch_item.created_at.iso8601
    }
  end

  # POST /batch_properties/:id/retry_item/:item_id
  def retry_item
    @batch_upload = current_user.batch_property_uploads.find(params[:id])
    @batch_item = @batch_upload.batch_property_items.find(params[:item_id])

    if @batch_item.retry_processing!
      render json: {
        success: true,
        message: "Item retry initiated successfully",
        item: batch_item_json(@batch_item)
      }
    else
      render json: {
        success: false,
        error: "Failed to retry item",
        errors: @batch_item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /batch_properties/:id
  def destroy
    @batch_upload = current_user.batch_property_uploads.find(params[:id])

    if @batch_upload.processing?
      render json: { error: "Cannot delete batch upload while processing" }, status: :unprocessable_entity
      return
    end

    @batch_upload.destroy
    render json: { message: "Batch upload deleted successfully" }
  end

  private

  def authenticate_web_request
    # For web requests (HTML, CSV, etc.) and AJAX requests with CSRF tokens, use session-based authentication
    unless current_user
      respond_to do |format|
        format.html { redirect_to login_path, alert: "Please sign in to continue" }
        format.csv { redirect_to login_path, alert: "Please sign in to download the template" }
        format.json do
          if params[:authenticity_token].present?
            # This is a web form submission via AJAX, redirect to login
            render json: { error: "Not Authorized", redirect_to: login_path }, status: :unauthorized
          else
            # This is a pure API request
            render json: { error: "Not Authorized" }, status: :unauthorized
          end
        end
      end
    end
  end

  def authorize_landlord
    unless current_user&.landlord?
      respond_to do |format|
        format.html { redirect_to properties_path, alert: "You must be a landlord to access batch property listing." }
        format.csv { redirect_to properties_path, alert: "You must be a landlord to download the template." }
        format.json { render json: { error: "Forbidden: You must be a landlord to access this feature" }, status: :forbidden }
      end
    end
  end

  def generate_csv_template
    # Always use manual CSV generation for reliability
    Rails.logger.info "Using manual CSV generation for template"
    generate_manual_csv_template
  end

  def generate_manual_csv_template
    # Manual CSV generation as fallback using dynamic headers
    headers = get_property_csv_headers
    example_values = generate_example_values(headers)

    # Manually format CSV
    csv_content = headers.join(",") + "\n"
    csv_content += example_values.map { |field| "\"#{field}\"" }.join(",") + "\n"

    csv_content
  end

  def get_property_csv_headers
    # Get property attributes dynamically from the Property model
    property_attributes = Property.column_names.reject do |attr|
      # Exclude system fields that shouldn't be in CSV
      %w[id user_id created_at updated_at].include?(attr)
    end

    # Add custom fields that aren't direct model attributes
    custom_fields = [ "photo_filenames" ]

    property_attributes + custom_fields
  end

  def generate_example_values(headers)
    # Generate realistic example values that will pass validation
    headers.map do |header|
      case header.to_s
      when "title"
        "Modern Downtown Apartment"
      when "description"
        "Stunning 2-bedroom apartment in the heart of downtown with city views"
      when "address"
        "123 Main Street, Unit 4B"
      when "city"
        "San Francisco"
      when "state"
        "CA"
      when "zip_code"
        "94102"
      when "price"
        "2800"
      when "bedrooms"
        "2"
      when "bathrooms"
        "2"
      when "square_feet"
        "1200"
      when "property_type"
        "apartment"
      when "availability_status"
        "0"
      when "photo_filenames"
        "photo1.jpg,photo2.jpg,photo3.jpg"
      when /.*_available$/, /.*_allowed$/, /.*_included$/, /furnished/, /air_conditioning/, /heating/, /gym/, /pool/, /balcony/, /laundry/
        # Boolean fields
        "true"
      else
        # For any other fields, provide empty string
        ""
      end
    end
  end

  def parse_csv_data(csv_data)
    # Always use manual CSV parsing for reliability
    Rails.logger.info "Using manual CSV parsing for batch property upload"
    parse_csv_manually(csv_data)
  end

  def parse_csv_manually(csv_data)
    lines = csv_data.split("\n")
    return [] if lines.empty?

    # Get headers from first line
    headers = lines[0].split(",").map { |h| h.strip.gsub(/^"|"$/, "").to_sym }

    properties = []
    lines[1..-1].each do |line|
      next if line.strip.empty?

      # Simple CSV parsing (handles basic quoted fields)
      values = []
      current_value = ""
      in_quotes = false

      line.each_char do |char|
        case char
        when '"'
          in_quotes = !in_quotes
        when ","
          if in_quotes
            current_value += char
          else
            values << current_value.strip
            current_value = ""
          end
        else
          current_value += char
        end
      end
      values << current_value.strip # Add the last value

      # Create hash from headers and values
      if values.length == headers.length
        property_hash = {}
        headers.each_with_index do |header, index|
          property_hash[header] = values[index]&.gsub(/^"|"$/, "") # Remove quotes
        end
        properties << property_hash
      else
        Rails.logger.warn "Skipping malformed CSV row: #{line}"
      end
    end

    properties
  end

  def validate_properties_data(properties_data)
    valid_properties = []
    invalid_properties = []
    errors = []

    properties_data.each_with_index do |property_data, index|
      row_number = index + 2 # +2 because CSV is 1-indexed and has header row

      # Create a temporary property for validation
      property = current_user.properties.build(sanitize_property_params(property_data))

      if property.valid?
        valid_properties << { data: property_data, row_number: row_number, property: property }
      else
        invalid_properties << { data: property_data, row_number: row_number, errors: property.errors.full_messages }
        errors << "Row #{row_number}: #{property.errors.full_messages.join(', ')}"
      end
    end

    {
      valid_properties: valid_properties,
      invalid_properties: invalid_properties,
      valid_count: valid_properties.count,
      invalid_count: invalid_properties.count,
      total_count: properties_data.count,
      errors: errors,
      summary: {
        total: properties_data.count,
        valid: valid_properties.count,
        invalid: invalid_properties.count,
        success_rate: properties_data.count > 0 ? (valid_properties.count.to_f / properties_data.count * 100).round(1) : 0
      }
    }
  end

  def create_batch_items(valid_properties)
    valid_properties.each do |property_info|
      @batch_upload.batch_property_items.create!(
        row_number: property_info[:row_number],
        property_data: property_info[:data].to_json,
        status: "pending"
      )
    end
  end

  def sanitize_property_params(property_data)
    # Convert string values to appropriate types
    sanitized = property_data.dup

    # Convert boolean fields (using actual Property model column names)
    boolean_fields = [ :parking_available, :pets_allowed, :furnished, :utilities_included,
                     :laundry, :air_conditioning, :heating, :internet_included,
                     :gym, :pool, :balcony ]

    boolean_fields.each do |field|
      if sanitized[field].present?
        sanitized[field] = [ "true", "1", "yes", "y" ].include?(sanitized[field].to_s.downcase)
      end
    end

    # Convert numeric fields
    numeric_fields = [ :price, :bedrooms, :bathrooms, :square_feet ]
    numeric_fields.each do |field|
      if sanitized[field].present?
        sanitized[field] = sanitized[field].to_f if field == :price || field == :square_feet
        sanitized[field] = sanitized[field].to_i if field == :bedrooms || field == :bathrooms
      end
    end

    # Set default values for required fields if missing
    sanitized[:availability_status] ||= "available"

    # Convert availability_status to enum value if it's a string
    if sanitized[:availability_status].present?
      status_mapping = {
        "available" => 0, "rented" => 1, "pending" => 2, "maintenance" => 3,
        "0" => 0, "1" => 1, "2" => 2, "3" => 3
      }
      sanitized[:availability_status] = status_mapping[sanitized[:availability_status].to_s] || 0
    end

    # Ensure property_type is valid
    if sanitized[:property_type].present?
      valid_types = %w[apartment house condo townhouse studio loft]
      unless valid_types.include?(sanitized[:property_type].to_s.downcase)
        sanitized[:property_type] = "apartment" # Default fallback
      end
    else
      sanitized[:property_type] = "apartment" # Default if missing
    end

    # Remove photo_filenames from property params (handled separately)
    sanitized.except(:photo_filenames)
  end

  def batch_upload_json(batch_upload)
    {
      id: batch_upload.id,
      filename: batch_upload.filename,
      status: batch_upload.status,
      total_items: batch_upload.total_items,
      valid_items: batch_upload.valid_items,
      invalid_items: batch_upload.invalid_items,
      processed_items: batch_upload.processed_items,
      successful_items: batch_upload.successful_items,
      failed_items: batch_upload.failed_items,
      created_at: batch_upload.created_at.iso8601,
      updated_at: batch_upload.updated_at.iso8601,
      error_message: batch_upload.error_message
    }
  end

  def batch_item_json(batch_item)
    property_data = JSON.parse(batch_item.property_data)

    {
      id: batch_item.id,
      row_number: batch_item.row_number,
      status: batch_item.status,
      property_data: property_data,
      property_id: batch_item.property_id,
      error_message: batch_item.error_message,
      created_at: batch_item.created_at.iso8601
    }
  end

  def calculate_progress(batch_upload)
    return 0 if batch_upload.total_items.zero?

    processed = batch_upload.processed_items || 0
    total = batch_upload.total_items

    (processed.to_f / total * 100).round(1)
  end
end
