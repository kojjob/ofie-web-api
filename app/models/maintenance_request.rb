class MaintenanceRequest < ApplicationRecord
  belongs_to :property
  belongs_to :tenant, class_name: "User"
  belongs_to :landlord, class_name: "User"
  belongs_to :assigned_to, class_name: "User", optional: true

  has_many_attached :photos
  has_many_attached :documents

  # Define priority levels as an enum
  enum :priority, {
    low: "low",
    medium: "medium",
    high: "high",
    emergency: "emergency"
  }

  # Define status as an enum
  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    scheduled: "scheduled",
    completed: "completed",
    cancelled: "cancelled",
    on_hold: "on_hold"
  }

  # Define categories as an enum
  enum :category, {
    plumbing: "plumbing",
    electrical: "electrical",
    hvac: "hvac",
    appliances: "appliances",
    flooring: "flooring",
    painting: "painting",
    windows_doors: "windows_doors",
    pest_control: "pest_control",
    cleaning: "cleaning",
    landscaping: "landscaping",
    security: "security",
    other: "other"
  }

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :priority, presence: true, inclusion: { in: priorities.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :category, presence: true, inclusion: { in: categories.keys }
  validates :requested_at, presence: true
  validates :estimated_cost, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :location_details, length: { maximum: 500 }
  validates :landlord_notes, length: { maximum: 1000 }
  validates :completion_notes, length: { maximum: 1000 }

  validate :scheduled_at_cannot_be_in_past, if: :scheduled_at?
  validate :completed_at_cannot_be_before_requested_at, if: :completed_at?
  validate :tenant_belongs_to_property
  validate :landlord_owns_property

  # Scopes for easy querying
  scope :by_property, ->(property_id) { where(property_id: property_id) }
  scope :by_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :by_landlord, ->(landlord_id) { where(landlord_id: landlord_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_category, ->(category) { where(category: category) }
  scope :urgent_requests, -> { where(urgent: true) }
  scope :recent, -> { order(requested_at: :desc) }
  scope :overdue, -> { where(status: [ "pending", "scheduled" ]).where("scheduled_at < ?", Time.current) }

  # Callbacks
  before_validation :set_landlord_from_property, on: :create
  before_validation :set_requested_at, on: :create
  after_update :notify_status_change, if: :saved_change_to_status?
  after_create :notify_landlord_of_new_request

  # Instance methods
  def overdue?
    scheduled? && scheduled_at && scheduled_at < Time.current
  end

  def days_since_requested
    (Time.current - requested_at) / 1.day
  end

  def can_be_completed?
    in_progress? || scheduled?
  end

  def can_be_cancelled?
    pending? || scheduled?
  end

  def priority_color
    case priority
    when "emergency" then "red"
    when "high" then "orange"
    when "medium" then "yellow"
    when "low" then "green"
    end
  end

  def status_color
    case status
    when "pending" then "yellow"
    when "in_progress" then "blue"
    when "scheduled" then "purple"
    when "completed" then "green"
    when "cancelled" then "gray"
    when "on_hold" then "orange"
    end
  end

  def formatted_estimated_cost
    estimated_cost ? "$#{estimated_cost}" : "Not estimated"
  end

  private

  def set_landlord_from_property
    self.landlord = property&.user if property
  end

  def set_requested_at
    self.requested_at ||= Time.current
  end

  def scheduled_at_cannot_be_in_past
    return unless scheduled_at && scheduled_at < Time.current

    errors.add(:scheduled_at, "cannot be in the past")
  end

  def completed_at_cannot_be_before_requested_at
    return unless completed_at && requested_at && completed_at < requested_at

    errors.add(:completed_at, "cannot be before request date")
  end

  def tenant_belongs_to_property
    return unless property && tenant

    # Check if tenant has an active lease for this property
    unless property.lease_agreements.active.exists?(tenant: tenant)
      errors.add(:tenant, "must have an active lease for this property")
    end
  end

  def landlord_owns_property
    return unless property && landlord

    unless property.user == landlord
      errors.add(:landlord, "must be the owner of the property")
    end
  end

  def notify_status_change
    old_status = status_was
    NotificationService.notify_maintenance_status_change(self, old_status)

    # Notify about assignment if assigned_to changed
    if saved_change_to_assigned_to_id? && assigned_to.present?
      NotificationService.notify_maintenance_assignment(self)
    end

    # Notify about completion
    if completed? && saved_change_to_status?
      NotificationService.notify_maintenance_completion(self)
    end
  end

  def notify_landlord_of_new_request
    NotificationService.notify_new_maintenance_request(self)
  end
end
