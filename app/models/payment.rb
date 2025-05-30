class Payment < ApplicationRecord
  belongs_to :lease_agreement
  belongs_to :user
  belongs_to :payment_method, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :payment_type, presence: true, inclusion: { in: %w[rent security_deposit late_fee utility maintenance_fee other] }
  validates :status, presence: true, inclusion: { in: %w[pending processing succeeded failed canceled refunded] }
  validates :payment_number, presence: true, uniqueness: true

  validate :due_date_reasonable

  scope :succeeded, -> { where(status: "succeeded") }
  scope :failed, -> { where(status: "failed") }
  scope :pending, -> { where(status: "pending") }
  scope :processing, -> { where(status: "processing") }
  scope :rent_payments, -> { where(payment_type: "rent") }
  scope :security_deposits, -> { where(payment_type: "security_deposit") }
  scope :by_lease, ->(lease_id) { where(lease_agreement_id: lease_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :overdue, -> { where("due_date < ? AND status IN (?)", Date.current, %w[pending failed]) }
  scope :due_soon, ->(days = 7) { where(due_date: Date.current..(Date.current + days.days)) }

  before_validation :generate_payment_number, on: :create
  before_validation :set_default_description, on: :create

  after_update :notify_payment_status_change, if: :saved_change_to_status?

  def mark_as_processing!
    update!(status: "processing")
  end

  def mark_as_succeeded!(stripe_charge_id: nil, paid_at: Time.current)
    update!(
      status: "succeeded",
      paid_at: paid_at,
      stripe_charge_id: stripe_charge_id
    )
  end

  def mark_as_failed!(failure_reason:)
    update!(
      status: "failed",
      failure_reason: failure_reason
    )
  end

  def mark_as_canceled!
    update!(status: "canceled")
  end

  def overdue?
    due_date.present? && due_date < Date.current && !succeeded?
  end

  def days_overdue
    return 0 unless overdue?

    (Date.current - due_date).to_i
  end

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end

  def pending?
    status == "pending"
  end

  def processing?
    status == "processing"
  end

  def can_retry?
    failed? || (pending? && created_at < 1.hour.ago)
  end

  def late_fee_applicable?
    rent_payment? && overdue? && days_overdue >= 5
  end

  def rent_payment?
    payment_type == "rent"
  end

  def security_deposit_payment?
    payment_type == "security_deposit"
  end

  def calculate_late_fee
    return 0 unless late_fee_applicable?

    # Example: $50 flat fee + 5% of rent amount
    base_fee = 50.0
    percentage_fee = amount * 0.05

    base_fee + percentage_fee
  end

  def self.create_rent_payment!(lease_agreement:, due_date:, amount: nil)
    create!(
      lease_agreement: lease_agreement,
      user: lease_agreement.tenant,
      payment_type: "rent",
      amount: amount || lease_agreement.monthly_rent,
      due_date: due_date,
      description: "Monthly rent for #{due_date.strftime('%B %Y')}"
    )
  end

  def self.create_security_deposit_payment!(lease_agreement:)
    create!(
      lease_agreement: lease_agreement,
      user: lease_agreement.tenant,
      payment_type: "security_deposit",
      amount: lease_agreement.security_deposit_amount,
      due_date: lease_agreement.lease_start_date,
      description: "Security deposit for lease #{lease_agreement.lease_number}"
    )
  end

  def self.total_revenue(start_date: nil, end_date: nil)
    scope = succeeded
    scope = scope.where("paid_at >= ?", start_date) if start_date
    scope = scope.where("paid_at <= ?", end_date) if end_date
    scope.sum(:amount)
  end

  private

  def generate_payment_number
    return if payment_number.present?

    loop do
      self.payment_number = "PAY-#{Date.current.strftime('%Y%m')}-#{SecureRandom.hex(6).upcase}"
      break unless self.class.exists?(payment_number: payment_number)
    end
  end

  def set_default_description
    return if description.present?

    case payment_type
    when "rent"
      self.description = "Monthly rent payment"
    when "security_deposit"
      self.description = "Security deposit"
    when "late_fee"
      self.description = "Late payment fee"
    else
      self.description = payment_type.humanize
    end
  end

  def due_date_reasonable
    return unless due_date.present?

    if due_date < 1.year.ago
      errors.add(:due_date, "cannot be more than 1 year in the past")
    elsif due_date > 1.year.from_now
      errors.add(:due_date, "cannot be more than 1 year in the future")
    end
  end

  def notify_payment_status_change
    case status
    when "succeeded"
      PaymentNotificationJob.perform_later(self, "payment_succeeded")
    when "failed"
      PaymentNotificationJob.perform_later(self, "payment_failed")
    end
  end
end
