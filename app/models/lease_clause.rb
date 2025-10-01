class LeaseClause < ApplicationRecord
  # Validations
  validates :category, presence: true
  validates :clause_text, presence: true

  # Categories for legal clauses
  CATEGORIES = %w[
    rent_payment
    security_deposit
    lease_term
    utilities
    maintenance
    pets
    parking
    subletting
    termination
    late_fees
    notice_requirements
    property_condition
    insurance
    liability
    house_rules
    smoking
    guests
    property_access
    repairs
    dispute_resolution
  ].freeze

  # Scopes
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :for_jurisdiction, ->(jurisdiction) { where(jurisdiction: [nil, jurisdiction]) }
  scope :recent, -> { order(created_at: :desc) }

  # Validations
  validates :category, inclusion: { in: CATEGORIES }

  # Class methods
  def self.find_for_category_and_jurisdiction(category, jurisdiction)
    by_category(category)
      .for_jurisdiction(jurisdiction)
      .order('jurisdiction DESC NULLS LAST') # Prefer jurisdiction-specific over generic
      .first
  end

  def self.required_for_jurisdiction(jurisdiction)
    required.for_jurisdiction(jurisdiction)
  end

  # Instance methods
  def replace_variables(values = {})
    text = clause_text.dup
    (variables || {}).each do |key, _placeholder|
      text.gsub!("{{#{key}}}", values[key].to_s) if values[key].present?
    end
    text
  end

  def jurisdiction_specific?
    jurisdiction.present?
  end

  def generic?
    jurisdiction.blank?
  end

  def variable_keys
    (variables || {}).keys
  end

  def has_variables?
    variable_keys.any?
  end
end
