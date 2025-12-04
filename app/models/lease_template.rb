class LeaseTemplate < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :jurisdiction, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :for_jurisdiction, ->(jurisdiction) { where(jurisdiction: jurisdiction) }
  scope :recent, -> { order(created_at: :desc) }

  # Class methods
  def self.find_for_property(property)
    jurisdiction = property.state || property.city
    active.for_jurisdiction(jurisdiction).first || active.first
  end

  # Instance methods
  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def duplicate
    dup.tap do |template|
      template.name = "#{name} (Copy)"
      template.active = false
    end
  end

  # Returns all clauses (required + optional) as a single array
  def all_clauses
    (required_clauses || []) + (optional_clauses || [])
  end

  # Returns count of total clauses
  def clause_count
    all_clauses.count
  end
end
