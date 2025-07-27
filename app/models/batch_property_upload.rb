class BatchPropertyUpload < ApplicationRecord
  belongs_to :user
  has_many :batch_property_items, dependent: :destroy

  # Define status as an enum
  enum :status, {
    pending: "pending",
    processing: "processing",
    validated: "validated",
    completed: "completed",
    failed: "failed",
    cancelled: "cancelled"
  }

  validates :filename, presence: true
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :total_items, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :valid_items, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :invalid_items, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :processed_items, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :successful_items, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :failed_items, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status: status) }
  scope :completed_successfully, -> { where(status: "completed", failed_items: 0) }
  scope :with_errors, -> { where("failed_items > 0 OR status = ?", "failed") }

  # Callbacks
  before_validation :set_defaults, on: :create
  after_update :update_completion_timestamp, if: :saved_change_to_status?

  # Instance methods
  def progress_percentage
    return 0 if total_items.nil? || total_items.zero?
    return 100 if completed?

    processed = processed_items || 0
    (processed.to_f / total_items * 100).round(1)
  end

  def success_rate
    return 0 if total_items.nil? || total_items.zero?

    successful = successful_items || 0
    (successful.to_f / total_items * 100).round(1)
  end

  def can_be_processed?
    validated? && valid_items && valid_items > 0
  end

  def can_be_cancelled?
    pending? || processing? || validated?
  end

  def processing_time
    return nil unless completed_at && created_at

    completed_at - created_at
  end

  def summary
    {
      total: total_items || 0,
      valid: valid_items || 0,
      invalid: invalid_items || 0,
      processed: processed_items || 0,
      successful: successful_items || 0,
      failed: failed_items || 0,
      progress: progress_percentage,
      success_rate: success_rate,
      processing_time: processing_time
    }
  end

  def has_errors?
    failed? || (failed_items && failed_items > 0)
  end

  def completed_with_errors?
    completed? && failed_items && failed_items > 0
  end

  def all_items_processed?
    return false if total_items.nil? || processed_items.nil?

    processed_items >= total_items
  end

  def mark_as_completed!
    update!(
      status: "completed",
      completed_at: Time.current,
      processed_items: total_items
    )
  end

  def mark_as_failed!(error_message)
    update!(
      status: "failed",
      error_message: error_message,
      completed_at: Time.current
    )
  end

  def increment_processed!
    increment!(:processed_items)

    # Check if all items are processed
    if all_items_processed?
      mark_as_completed!
    end
  end

  def increment_successful!
    increment!(:successful_items)
  end

  def increment_failed!
    increment!(:failed_items)
  end

  # Class methods
  def self.cleanup_old_uploads(days_old = 30)
    # Delete uploads older than specified days
    old_uploads = where("created_at < ?", days_old.days.ago)

    old_uploads.each do |upload|
      # Delete associated files if any
      upload.destroy
    end
  end

  def self.statistics_for_user(user)
    uploads = where(user: user)

    {
      total_uploads: uploads.count,
      completed_uploads: uploads.completed.count,
      failed_uploads: uploads.failed.count,
      total_properties_uploaded: uploads.sum(:successful_items),
      average_success_rate: uploads.where.not(total_items: 0).average("successful_items::float / total_items * 100")&.round(1) || 0,
      last_upload: uploads.recent.first&.created_at
    }
  end

  private

  def set_defaults
    self.status ||= "pending"
    self.total_items ||= 0
    self.valid_items ||= 0
    self.invalid_items ||= 0
    self.processed_items ||= 0
    self.successful_items ||= 0
    self.failed_items ||= 0
  end

  def update_completion_timestamp
    if completed? || failed?
      update_column(:completed_at, Time.current) unless completed_at
    end
  end
end
