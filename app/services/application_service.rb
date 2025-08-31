# Base service class for all service objects
class ApplicationService
  # Class method to instantiate and call the service
  def self.call(...)
    new(...).call
  end

  private

  # Return a successful result with optional data
  def success(data = {})
    ServiceResult.new(success: true, data: data, errors: [])
  end

  # Return a failure result with errors
  def failure(errors, data = {})
    errors = Array(errors)
    ServiceResult.new(success: false, data: data, errors: errors)
  end

  # Check if a record is valid and return appropriate result
  def validate_record(record)
    if record.valid?
      success(record: record)
    else
      failure(record.errors.full_messages, record: record)
    end
  end

  # Execute a block within a transaction
  def with_transaction(&block)
    ActiveRecord::Base.transaction(&block)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.record.errors.full_messages)
  rescue StandardError => e
    Rails.logger.error "Service error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    failure("An unexpected error occurred: #{e.message}")
  end

  # Log service execution
  def log_execution(message, level = :info)
    Rails.logger.send(level, "[#{self.class.name}] #{message}")
  end
end

# Service result object for consistent response structure
class ServiceResult
  attr_reader :data, :errors

  def initialize(success:, data: {}, errors: [])
    @success = success
    @data = OpenStruct.new(data)
    @errors = errors
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def error_message
    errors.join(", ")
  end

  # Allow direct access to data attributes
  def method_missing(method, *args, &block)
    if @data.respond_to?(method)
      @data.send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    @data.respond_to?(method) || super
  end
end