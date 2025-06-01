class BatchPropertyItem < ApplicationRecord
  belongs_to :batch_property_upload
  belongs_to :property, optional: true
  
  # Define status as an enum
  enum :status, {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed',
    skipped: 'skipped'
  }
  
  validates :row_number, presence: true, numericality: { greater_than: 0 }
  validates :property_data, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  
  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_row_number, -> { order(:row_number) }
  scope :successful, -> { where(status: 'completed').where.not(property_id: nil) }
  scope :failed_items, -> { where(status: 'failed') }
  scope :pending_items, -> { where(status: 'pending') }
  
  # Callbacks
  before_validation :set_defaults, on: :create
  after_update :update_batch_counters, if: :saved_change_to_status?
  
  # Instance methods
  def property_data_hash
    @property_data_hash ||= JSON.parse(property_data) if property_data.present?
  end
  
  def property_title
    property_data_hash&.dig('title') || "Property ##{row_number}"
  end
  
  def property_address
    data = property_data_hash
    return nil unless data
    
    address_parts = [data['address'], data['city']].compact
    address_parts.join(', ') if address_parts.any?
  end
  
  def property_price
    property_data_hash&.dig('price')&.to_f
  end
  
  def photo_filenames
    filenames = property_data_hash&.dig('photo_filenames')
    return [] unless filenames.present?
    
    filenames.split(',').map(&:strip).reject(&:blank?)
  end
  
  def has_photos?
    photo_filenames.any?
  end
  
  def can_be_processed?
    pending? && property_data.present?
  end
  
  def can_be_retried?
    failed? && property_data.present?
  end
  
  def mark_as_processing!
    update!(status: 'processing', started_at: Time.current)
  end
  
  def mark_as_completed!(property)
    update!(
      status: 'completed',
      property: property,
      completed_at: Time.current
    )
  end
  
  def mark_as_failed!(error_message)
    update!(
      status: 'failed',
      error_message: error_message,
      completed_at: Time.current
    )
  end
  
  def mark_as_skipped!(reason)
    update!(
      status: 'skipped',
      error_message: reason,
      completed_at: Time.current
    )
  end
  
  def processing_time
    return nil unless completed_at && started_at
    
    completed_at - started_at
  end
  
  def retry_processing!
    return false unless can_be_retried?
    
    update!(
      status: 'pending',
      error_message: nil,
      started_at: nil,
      completed_at: nil,
      property: nil
    )
  end
  
  def create_property!
    return false unless can_be_processed?
    
    mark_as_processing!
    
    begin
      # Parse property data
      data = property_data_hash
      user = batch_property_upload.user
      
      # Create property
      property = user.properties.build(sanitize_property_data(data))
      
      if property.save
        # Handle photo attachments if specified
        attach_photos(property, photo_filenames) if has_photos?
        
        mark_as_completed!(property)
        true
      else
        mark_as_failed!(property.errors.full_messages.join(', '))
        false
      end
      
    rescue StandardError => e
      mark_as_failed!("Processing error: #{e.message}")
      false
    end
  end
  
  def validation_errors
    return [] unless property_data.present?
    
    begin
      data = property_data_hash
      user = batch_property_upload.user
      property = user.properties.build(sanitize_property_data(data))
      
      property.valid? ? [] : property.errors.full_messages
    rescue StandardError => e
      ["Data parsing error: #{e.message}"]
    end
  end
  
  def preview_data
    data = property_data_hash
    return {} unless data
    
    {
      title: data['title'],
      address: property_address,
      price: property_price,
      bedrooms: data['bedrooms']&.to_i,
      bathrooms: data['bathrooms']&.to_i,
      property_type: data['property_type'],
      square_feet: data['square_feet']&.to_i,
      photo_count: photo_filenames.count,
      has_description: data['description'].present?
    }
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
  
  def update_batch_counters
    batch_upload = batch_property_upload
    
    case status
    when 'completed'
      batch_upload.increment_processed!
      batch_upload.increment_successful!
    when 'failed', 'skipped'
      batch_upload.increment_processed!
      batch_upload.increment_failed! if failed?
    end
  end
  
  def sanitize_property_data(data)
    # Convert string values to appropriate types
    sanitized = data.dup
    
    # Convert boolean fields
    boolean_fields = %w[parking_available pets_allowed furnished utilities_included 
                       laundry_available air_conditioning heating internet_included
                       gym_access pool_access balcony garden]
    
    boolean_fields.each do |field|
      if sanitized[field].present?
        sanitized[field] = ['true', '1', 'yes', 'y'].include?(sanitized[field].to_s.downcase)
      end
    end
    
    # Convert numeric fields
    sanitized['price'] = sanitized['price'].to_f if sanitized['price'].present?
    sanitized['bedrooms'] = sanitized['bedrooms'].to_i if sanitized['bedrooms'].present?
    sanitized['bathrooms'] = sanitized['bathrooms'].to_i if sanitized['bathrooms'].present?
    sanitized['square_feet'] = sanitized['square_feet'].to_f if sanitized['square_feet'].present?
    
    # Remove fields that aren't property attributes
    sanitized.except('photo_filenames')
  end
  
  def attach_photos(property, filenames)
    # This would be implemented to handle photo attachments
    # For now, we'll just log the filenames that should be attached
    Rails.logger.info "Photos to attach for property #{property.id}: #{filenames.join(', ')}"
    
    # TODO: Implement photo attachment logic
    # This could involve:
    # 1. Looking for files in a specific upload directory
    # 2. Downloading from URLs if filenames are URLs
    # 3. Matching files by naming convention
  end
end
