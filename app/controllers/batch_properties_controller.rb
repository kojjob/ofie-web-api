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
                    type: 'text/csv',
                    disposition: 'attachment'
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
        status: 'processing'
      )

      # Process CSV file
      csv_data = params[:csv_file].read
      properties_data = parse_csv_data(csv_data)
      
      # Validate and create batch items
      validation_results = validate_properties_data(properties_data)
      
      if validation_results[:valid_count] > 0
        create_batch_items(validation_results[:valid_properties])
        @batch_upload.update!(
          status: 'validated',
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
        @batch_upload.update!(status: 'failed', error_message: "No valid properties found")
        render json: {
          error: "No valid properties found in CSV",
          validation_errors: validation_results[:errors]
        }, status: :unprocessable_entity
      end

    rescue CSV::MalformedCSVError => e
      @batch_upload&.update!(status: 'failed', error_message: "Invalid CSV format: #{e.message}")
      render json: { error: "Invalid CSV format: #{e.message}" }, status: :unprocessable_entity
    rescue StandardError => e
      @batch_upload&.update!(status: 'failed', error_message: e.message)
      render json: { error: "Upload failed: #{e.message}" }, status: :internal_server_error
    end
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

    unless @batch_upload.validated?
      render json: { error: "Batch upload must be validated before processing" }, status: :unprocessable_entity
      return
    end

    # Process in background job
    BatchPropertyProcessorJob.perform_later(@batch_upload.id)

    @batch_upload.update!(status: 'processing')

    render json: {
      message: "Batch processing started",
      batch_upload: batch_upload_json(@batch_upload)
    }
  end

  # GET /batch_properties/:id/status
  def status
    @batch_upload = current_user.batch_property_uploads.find(params[:id])
    
    render json: {
      batch_upload: batch_upload_json(@batch_upload),
      progress: calculate_progress(@batch_upload)
    }
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
    # For web requests (HTML, CSV, etc.), use session-based authentication
    unless current_user
      respond_to do |format|
        format.html { redirect_to login_path, alert: "Please sign in to continue" }
        format.csv { redirect_to login_path, alert: "Please sign in to download the template" }
        format.json { render json: { error: "Not Authorized" }, status: :unauthorized }
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
    # CSV should be loaded at application level, but add fallback just in case
    unless defined?(CSV)
      Rails.logger.warn "CSV library not available, using manual CSV generation"
      return generate_manual_csv_template
    end

    CSV.generate(headers: true) do |csv|
      # Header row with all property fields
      csv << [
        'title', 'description', 'address', 'city', 'price', 'bedrooms', 'bathrooms',
        'square_feet', 'property_type', 'availability_status', 'parking_available',
        'pets_allowed', 'furnished', 'utilities_included', 'laundry_available',
        'air_conditioning', 'heating', 'internet_included', 'gym_access',
        'pool_access', 'balcony', 'garden', 'photo_filenames'
      ]
      
      # Example row
      csv << [
        'Beautiful 2BR Apartment Downtown',
        'Spacious apartment with modern amenities in the heart of downtown. Close to public transportation and shopping.',
        '123 Main Street, Apt 4B',
        'New York',
        '2500',
        '2',
        '1',
        '900',
        'apartment',
        'available',
        'true',
        'false',
        'false',
        'true',
        'true',
        'true',
        'true',
        'true',
        'false',
        'false',
        'true',
        'false',
        'property_1_photo_1.jpg,property_1_photo_2.jpg,property_1_photo_3.jpg'
      ]
    end
  end

  def generate_manual_csv_template
    # Manual CSV generation as fallback
    headers = [
      'title', 'description', 'address', 'city', 'price', 'bedrooms', 'bathrooms',
      'square_feet', 'property_type', 'availability_status', 'parking_available',
      'pets_allowed', 'furnished', 'utilities_included', 'laundry_available',
      'air_conditioning', 'heating', 'internet_included', 'gym_access',
      'pool_access', 'balcony', 'garden', 'photo_filenames'
    ]

    example_row = [
      'Beautiful 2BR Apartment Downtown',
      'Spacious apartment with modern amenities in the heart of downtown. Close to public transportation and shopping.',
      '123 Main Street, Apt 4B',
      'New York',
      '2500',
      '2',
      '1',
      '900',
      'apartment',
      'available',
      'true',
      'false',
      'false',
      'true',
      'true',
      'true',
      'true',
      'true',
      'false',
      'false',
      'true',
      'false',
      'property_1_photo_1.jpg,property_1_photo_2.jpg,property_1_photo_3.jpg'
    ]

    # Manually format CSV
    csv_content = headers.join(',') + "\n"
    csv_content += example_row.map { |field| "\"#{field}\"" }.join(',') + "\n"

    csv_content
  end

  def parse_csv_data(csv_data)
    unless defined?(CSV)
      Rails.logger.error "CSV library not available for parsing uploaded data"
      raise StandardError, "CSV processing is not available. Please contact support."
    end

    properties = []
    CSV.parse(csv_data, headers: true, header_converters: :symbol) do |row|
      properties << row.to_hash
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
        status: 'pending'
      )
    end
  end

  def sanitize_property_params(property_data)
    # Convert string values to appropriate types
    sanitized = property_data.dup
    
    # Convert boolean fields
    boolean_fields = [:parking_available, :pets_allowed, :furnished, :utilities_included, 
                     :laundry_available, :air_conditioning, :heating, :internet_included,
                     :gym_access, :pool_access, :balcony, :garden]
    
    boolean_fields.each do |field|
      if sanitized[field].present?
        sanitized[field] = ['true', '1', 'yes', 'y'].include?(sanitized[field].to_s.downcase)
      end
    end
    
    # Convert numeric fields
    numeric_fields = [:price, :bedrooms, :bathrooms, :square_feet]
    numeric_fields.each do |field|
      if sanitized[field].present?
        sanitized[field] = sanitized[field].to_f if field == :price || field == :square_feet
        sanitized[field] = sanitized[field].to_i if field == :bedrooms || field == :bathrooms
      end
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
