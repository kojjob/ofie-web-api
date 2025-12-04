class LeaseAgreement < ApplicationRecord
  belongs_to :rental_application
  belongs_to :landlord, class_name: "User"
  belongs_to :tenant, class_name: "User"
  belongs_to :property

  has_many :payments, dependent: :destroy
  has_many :payment_schedules, dependent: :destroy
  has_one :security_deposit, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[draft pending_signatures signed active terminated expired] }
  validates :lease_start_date, presence: true
  validates :lease_end_date, presence: true
  validates :monthly_rent, presence: true, numericality: { greater_than: 0 }
  validates :security_deposit_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :lease_number, presence: true, uniqueness: true

  validate :end_date_after_start_date
  validate :lease_dates_valid

  scope :active, -> { where(status: "active") }
  scope :signed, -> { where(status: "signed") }
  scope :pending, -> { where(status: "pending_signatures") }
  scope :by_landlord, ->(landlord_id) { where(landlord_id: landlord_id) }
  scope :by_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :by_property, ->(property_id) { where(property_id: property_id) }
  scope :expiring_soon, ->(days = 30) { where(lease_end_date: Date.current..days.days.from_now) }
  scope :ai_generated, -> { where(ai_generated: true) }
  scope :manually_created, -> { where(ai_generated: false) }
  scope :reviewed_by_landlord, -> { where(reviewed_by_landlord: true) }
  scope :pending_review, -> { where(reviewed_by_landlord: false, ai_generated: true) }

  before_validation :generate_lease_number, on: :create
  before_validation :set_security_deposit_amount, on: :create

  after_create :create_security_deposit_record
  after_create :create_rent_payment_schedule

  def sign_by_tenant!
    update!(tenant_signed_at: Time.current, status: check_fully_signed_status)
  end

  def sign_by_landlord!
    update!(landlord_signed_at: Time.current, status: check_fully_signed_status)
  end

  def activate!
    return false unless fully_signed?

    update!(status: "active")
  end

  def terminate!(reason = nil)
    update!(
      status: "terminated",
      termination_date: Date.current,
      termination_reason: reason
    )

    # Deactivate payment schedules
    payment_schedules.update_all(is_active: false)
  end

  def fully_signed?
    tenant_signed_at.present? && landlord_signed_at.present?
  end

  def days_remaining
    return 0 if lease_end_date < Date.current

    (lease_end_date - Date.current).to_i
  end

  def monthly_payment_due
    monthly_rent
  end

  def next_rent_due_date
    payment_schedules.rent.active.first&.next_payment_date
  end

  def total_payments_made
    payments.succeeded.sum(:amount)
  end

  def outstanding_balance
    # Calculate based on payment schedules vs actual payments
    expected_payments = calculate_expected_payments
    actual_payments = total_payments_made

    [ expected_payments - actual_payments, 0 ].max
  end

  private

  def generate_lease_number
    return if lease_number.present?

    loop do
      self.lease_number = "LEASE-#{Date.current.strftime('%Y%m')}-#{SecureRandom.hex(4).upcase}"
      break unless self.class.exists?(lease_number: lease_number)
    end
  end

  def set_security_deposit_amount
    return if security_deposit_amount.present?

    # Default to one month's rent
    self.security_deposit_amount = monthly_rent if monthly_rent.present?
  end

  def check_fully_signed_status
    if tenant_signed_at.present? && landlord_signed_at.present?
      "signed"
    else
      "pending_signatures"
    end
  end

  def end_date_after_start_date
    return unless lease_start_date.present? && lease_end_date.present?

    errors.add(:lease_end_date, "must be after start date") if lease_end_date <= lease_start_date
  end

  def lease_dates_valid
    return unless lease_start_date.present?

    errors.add(:lease_start_date, "cannot be more than 1 year in the past") if lease_start_date < 1.year.ago
    errors.add(:lease_start_date, "cannot be more than 1 year in the future") if lease_start_date > 1.year.from_now
  end

  def create_security_deposit_record
    SecurityDeposit.create!(
      lease_agreement: self,
      amount: security_deposit_amount,
      status: "pending"
    )
  end

  def create_rent_payment_schedule
    PaymentSchedule.create!(
      lease_agreement: self,
      payment_type: "rent",
      amount: monthly_rent,
      frequency: "monthly",
      start_date: lease_start_date,
      end_date: lease_end_date,
      next_payment_date: lease_start_date,
      day_of_month: lease_start_date.day,
      description: "Monthly rent payment"
    )
  end

  def calculate_expected_payments
    # Simple calculation - can be enhanced based on business logic
    months_elapsed = ((Date.current.year - lease_start_date.year) * 12) + (Date.current.month - lease_start_date.month)
    months_elapsed = [ months_elapsed, 0 ].max

    months_elapsed * monthly_rent
  end
end
