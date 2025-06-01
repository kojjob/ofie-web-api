class PaymentMethod < ApplicationRecord
  belongs_to :user
  has_many :payments, dependent: :nullify

  validates :stripe_payment_method_id, presence: true, uniqueness: true
  validates :payment_type, presence: true, inclusion: { in: %w[card bank_account] }
  validates :last_four, presence: true, length: { is: 4 }
  validates :user_id, presence: true

  validate :only_one_default_per_user

  scope :cards, -> { where(payment_type: "card") }
  scope :bank_accounts, -> { where(payment_type: "bank_account") }
  scope :default_methods, -> { where(is_default: true) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  before_destroy :ensure_not_default_if_others_exist
  after_create :set_as_default_if_first

  def make_default!
    transaction do
      # Remove default from other payment methods for this user
      user.payment_methods.where.not(id: id).update_all(is_default: false)
      update!(is_default: true)
    end
  end

  def display_name
    case payment_type
    when "card"
      "#{brand&.capitalize} ending in #{last_four}"
    when "bank_account"
      "Bank account ending in #{last_four}"
    else
      "Payment method ending in #{last_four}"
    end
  end

  def card?
    payment_type == "card"
  end

  def bank_account?
    payment_type == "bank_account"
  end

  def expired?
    return false unless card? && exp_month.present? && exp_year.present?

    expiration_date = Date.new(exp_year, exp_month, -1) # Last day of expiration month
    expiration_date < Date.current
  end

  def expires_soon?(months = 2)
    return false unless card? && exp_month.present? && exp_year.present?

    expiration_date = Date.new(exp_year, exp_month, -1)
    expiration_date <= months.months.from_now
  end

  def detach_from_stripe!
    return unless stripe_payment_method_id.present?

    begin
      stripe_pm = Stripe::PaymentMethod.retrieve(stripe_payment_method_id)
      stripe_pm.detach
      destroy!
    rescue Stripe::StripeError => e
      Rails.logger.error "Failed to detach payment method #{stripe_payment_method_id}: #{e.message}"
      raise e
    end
  end

  def self.create_from_stripe!(user:, stripe_payment_method:)
    pm_data = stripe_payment_method

    case pm_data.type
    when "card"
      card_data = pm_data.card
      create!(
        user: user,
        stripe_payment_method_id: pm_data.id,
        payment_type: "card",
        last_four: card_data.last4,
        brand: card_data.brand,
        exp_month: card_data.exp_month,
        exp_year: card_data.exp_year,
        billing_name: pm_data.billing_details&.name,
        billing_address: pm_data.billing_details&.address&.to_h
      )
    when "us_bank_account"
      bank_data = pm_data.us_bank_account
      create!(
        user: user,
        stripe_payment_method_id: pm_data.id,
        payment_type: "bank_account",
        last_four: bank_data.last4,
        brand: bank_data.bank_name,
        billing_name: pm_data.billing_details&.name,
        billing_address: pm_data.billing_details&.address&.to_h
      )
    else
      raise ArgumentError, "Unsupported payment method type: #{pm_data.type}"
    end
  end

  private

  def only_one_default_per_user
    return unless is_default?

    existing_default = user.payment_methods.where(is_default: true).where.not(id: id).first
    if existing_default.present?
      errors.add(:is_default, "can only have one default payment method per user")
    end
  end

  def ensure_not_default_if_others_exist
    return unless is_default?

    other_methods = user.payment_methods.where.not(id: id)
    if other_methods.exists?
      errors.add(:base, "Cannot delete the default payment method when other methods exist. Please set another method as default first.")
      throw :abort
    end
  end

  def set_as_default_if_first
    return if user.payment_methods.where.not(id: id).exists?

    update_column(:is_default, true)
  end
end
