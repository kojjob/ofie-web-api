class PaymentSchedule < ApplicationRecord
  belongs_to :lease_agreement

  validates :payment_type, presence: true, inclusion: { in: %w[rent utility maintenance_fee parking_fee pet_fee other] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :frequency, presence: true, inclusion: { in: %w[weekly monthly quarterly annually] }
  validates :start_date, presence: true
  validates :next_payment_date, presence: true

  validate :end_date_after_start_date
  validate :next_payment_date_reasonable

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :auto_pay_enabled, -> { where(auto_pay: true) }
  scope :rent, -> { where(payment_type: "rent") }
  scope :utilities, -> { where(payment_type: "utility") }
  scope :due_soon, ->(days = 7) { where(next_payment_date: Date.current..(Date.current + days.days)) }
  scope :overdue, -> { where("next_payment_date < ? AND is_active = ?", Date.current, true) }
  scope :by_lease, ->(lease_id) { where(lease_agreement_id: lease_id) }

  after_update :create_payment_if_due, if: :saved_change_to_next_payment_date?

  def activate!
    update!(is_active: true)
  end

  def deactivate!
    update!(is_active: false)
  end

  def enable_auto_pay!
    update!(auto_pay: true)
  end

  def disable_auto_pay!
    update!(auto_pay: false)
  end

  def calculate_next_payment_date(from_date = next_payment_date)
    case frequency
    when "weekly"
      from_date + 1.week
    when "monthly"
      if day_of_month.present?
        next_month = from_date.next_month
        # Handle edge case where day doesn't exist in next month (e.g., Jan 31 -> Feb 28)
        begin
          Date.new(next_month.year, next_month.month, day_of_month)
        rescue Date::Error
          next_month.end_of_month
        end
      else
        from_date + 1.month
      end
    when "quarterly"
      from_date + 3.months
    when "annually"
      from_date + 1.year
    else
      from_date + 1.month # Default fallback
    end
  end

  def advance_to_next_payment!
    new_next_date = calculate_next_payment_date

    # Don't advance beyond lease end date
    if end_date.present? && new_next_date > end_date
      deactivate!
      return false
    end

    update!(next_payment_date: new_next_date)
    true
  end

  def create_payment_for_current_period!
    return unless is_active?
    return if payment_already_exists_for_period?

    payment = Payment.create!(
      lease_agreement: lease_agreement,
      user: lease_agreement.tenant,
      payment_type: payment_type,
      amount: amount,
      due_date: next_payment_date,
      description: generate_payment_description
    )

    advance_to_next_payment!
    payment
  end

  def overdue?
    is_active? && next_payment_date < Date.current
  end

  def due_today?
    is_active? && next_payment_date == Date.current
  end

  def due_soon?(days = 7)
    is_active? && next_payment_date.between?(Date.current, Date.current + days.days)
  end

  def days_until_due
    return 0 unless is_active?

    (next_payment_date - Date.current).to_i
  end

  def rent_schedule?
    payment_type == "rent"
  end

  def utility_schedule?
    payment_type == "utility"
  end

  def self.process_due_payments!
    # Find all schedules that are due and create payments
    due_schedules = active.where("next_payment_date <= ?", Date.current)

    created_payments = []

    due_schedules.find_each do |schedule|
      begin
        payment = schedule.create_payment_for_current_period!
        created_payments << payment if payment
      rescue => e
        Rails.logger.error "Failed to create payment for schedule #{schedule.id}: #{e.message}"
      end
    end

    created_payments
  end

  def self.auto_pay_eligible
    active.auto_pay_enabled.joins(:lease_agreement)
      .where("lease_agreements.status = ?", "active")
  end

  def self.expiring_soon(days = 30)
    active.where("end_date IS NOT NULL AND end_date <= ?", days.days.from_now)
  end

  private

  def end_date_after_start_date
    return unless start_date.present? && end_date.present?

    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end

  def next_payment_date_reasonable
    return unless next_payment_date.present?

    if next_payment_date < start_date
      errors.add(:next_payment_date, "cannot be before start date")
    elsif next_payment_date > 2.years.from_now
      errors.add(:next_payment_date, "cannot be more than 2 years in the future")
    end
  end

  def payment_already_exists_for_period?
    # Check if a payment already exists for this period
    Payment.exists?(
      lease_agreement: lease_agreement,
      payment_type: payment_type,
      due_date: next_payment_date
    )
  end

  def generate_payment_description
    case payment_type
    when "rent"
      "Monthly rent for #{next_payment_date.strftime('%B %Y')}"
    when "utility"
      "Utility payment for #{next_payment_date.strftime('%B %Y')}"
    when "maintenance_fee"
      "Maintenance fee for #{next_payment_date.strftime('%B %Y')}"
    else
      "#{payment_type.humanize} payment for #{next_payment_date.strftime('%B %Y')}"
    end
  end

  def create_payment_if_due
    return unless is_active? && next_payment_date <= Date.current

    CreateScheduledPaymentJob.perform_later(self)
  end
end
