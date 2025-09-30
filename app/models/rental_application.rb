class RentalApplication < ApplicationRecord
  belongs_to :property
  belongs_to :tenant, class_name: "User"
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_one :lease_agreement, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[pending under_review approved rejected withdrawn] }
  validates :application_date, presence: true
  validates :move_in_date, presence: true
  validates :monthly_income, presence: true, numericality: { greater_than: 0 }
  validates :employment_status, presence: true
  validates :previous_address, presence: true
  validates :references_contact, presence: true

  validate :move_in_date_cannot_be_in_past
  validate :monthly_income_sufficient

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :under_review, -> { where(status: "under_review") }
  scope :by_property, ->(property_id) { where(property_id: property_id) }
  scope :by_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }

  before_validation :set_application_date, on: :create

  def approve!
    update!(status: "approved", reviewed_at: Time.current)
  end

  def reject!
    update!(status: "rejected", reviewed_at: Time.current)
  end

  def under_review!
    update!(status: "under_review", reviewed_at: Time.current)
  end

  def can_create_lease?
    status == "approved"
  end

  def income_to_rent_ratio
    return 0 if property.nil? || property.price.nil? || monthly_income.nil?

    monthly_income / property.price
  end

  private

  def set_application_date
    self.application_date ||= Date.current
  end

  def move_in_date_cannot_be_in_past
    return unless move_in_date.present?

    errors.add(:move_in_date, "can't be in the past") if move_in_date < Date.current
  end

  def monthly_income_sufficient
    return unless monthly_income.present? && property&.price.present?

    # Typically require 3x rent in income
    minimum_income = property.price * 3
    if monthly_income < minimum_income
      errors.add(:monthly_income, "should be at least 3 times the monthly rent (#{minimum_income})")
    end
  end
end
