class SecurityDeposit < ApplicationRecord
  belongs_to :lease_agreement

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending collected refunded partially_refunded] }
  validates :lease_agreement_id, uniqueness: true

  validate :refund_amount_not_greater_than_amount
  validate :refund_details_present_when_refunding

  scope :pending, -> { where(status: "pending") }
  scope :collected, -> { where(status: "collected") }
  scope :refunded, -> { where(status: "refunded") }
  scope :partially_refunded, -> { where(status: "partially_refunded") }
  scope :refundable, -> { where(status: [ "collected", "partially_refunded" ]) }

  def mark_as_collected!(stripe_payment_intent_id: nil, collected_at: Time.current, notes: nil)
    update!(
      status: "collected",
      collected_at: collected_at,
      stripe_payment_intent_id: stripe_payment_intent_id,
      collection_notes: notes
    )
  end

  def process_refund!(refund_amount:, reason:, deductions: [], stripe_refund_id: nil)
    total_deductions = calculate_total_deductions(deductions)
    final_refund_amount = refund_amount - total_deductions

    raise ArgumentError, "Refund amount cannot be negative" if final_refund_amount < 0
    raise ArgumentError, "Refund amount exceeds available deposit" if final_refund_amount > refundable_amount

    transaction do
      update!(
        refund_amount: (self.refund_amount || 0) + final_refund_amount,
        refunded_at: Time.current,
        refund_reason: reason,
        stripe_refund_id: stripe_refund_id,
        deductions: (self.deductions || []) + deductions,
        status: determine_refund_status(final_refund_amount)
      )

      # Create notification
      SecurityDepositNotificationJob.perform_later(self, "refund_processed")
    end
  end

  def add_deduction!(description:, amount:, date: Date.current)
    raise ArgumentError, "Cannot add deductions to unrefunded deposit" unless refundable?

    new_deduction = {
      description: description,
      amount: amount.to_f,
      date: date.to_s,
      created_at: Time.current.iso8601
    }

    current_deductions = deductions || []
    update!(deductions: current_deductions + [ new_deduction ])
  end

  def total_deductions
    return 0 if deductions.blank?

    deductions.sum { |d| d["amount"].to_f }
  end

  def refundable_amount
    amount - total_deductions - (refund_amount || 0)
  end

  def collected?
    status == "collected"
  end

  def refunded?
    status == "refunded"
  end

  def partially_refunded?
    status == "partially_refunded"
  end

  def pending?
    status == "pending"
  end

  def refundable?
    collected? || partially_refunded?
  end

  def fully_refunded?
    refunded? || (refund_amount.present? && refund_amount >= amount)
  end

  def days_since_collection
    return 0 unless collected_at.present?

    (Time.current.to_date - collected_at.to_date).to_i
  end

  def eligible_for_refund?
    # Typically eligible after lease ends
    refundable? && lease_agreement.lease_end_date <= Date.current
  end

  def generate_refund_breakdown
    {
      original_amount: amount,
      total_deductions: total_deductions,
      previous_refunds: refund_amount || 0,
      available_for_refund: refundable_amount,
      deductions_detail: deductions || []
    }
  end

  def self.pending_collection
    joins(:lease_agreement)
      .where(status: "pending")
      .where("lease_agreements.lease_start_date <= ?", Date.current)
  end

  def self.eligible_for_refund
    joins(:lease_agreement)
      .where(status: [ "collected", "partially_refunded" ])
      .where("lease_agreements.lease_end_date <= ?", Date.current)
  end

  def self.overdue_collection(days = 30)
    joins(:lease_agreement)
      .where(status: "pending")
      .where("lease_agreements.lease_start_date < ?", days.days.ago)
  end

  private

  def calculate_total_deductions(new_deductions)
    new_deductions.sum { |d| d[:amount].to_f }
  end

  def determine_refund_status(refund_amount)
    total_refunded = (self.refund_amount || 0) + refund_amount

    if total_refunded >= amount
      "refunded"
    elsif total_refunded > 0
      "partially_refunded"
    else
      "collected"
    end
  end

  def refund_amount_not_greater_than_amount
    return unless refund_amount.present? && amount.present?

    if refund_amount > amount
      errors.add(:refund_amount, "cannot be greater than the original deposit amount")
    end
  end

  def refund_details_present_when_refunding
    return unless refunded_at.present?

    errors.add(:refund_reason, "must be present when deposit is refunded") if refund_reason.blank?
    errors.add(:refund_amount, "must be present when deposit is refunded") if refund_amount.blank?
  end
end
