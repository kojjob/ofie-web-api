class PropertyViewing < ApplicationRecord
  belongs_to :user
  belongs_to :property

  enum :status, {
    pending: 0,
    confirmed: 1,
    completed: 2,
    cancelled: 3,
    no_show: 4
  }

  enum :viewing_type, {
    in_person: 0,
    virtual: 1
  }

  validates :scheduled_at, presence: true
  validates :status, presence: true
  validates :viewing_type, presence: true
  validates :scheduled_at, comparison: { greater_than: -> { Time.current + 2.hours } }, on: :create
  validates :contact_phone, format: { with: /\A[\+]?[1-9]?[0-9]{7,15}\z/, message: "Invalid phone format" }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, presence: true

  # Prevent double booking
  validates :scheduled_at, uniqueness: {
    scope: :property_id,
    conditions: -> { where.not(status: [ "cancelled", "no_show" ]) },
    message: "This time slot is already booked"
  }

  scope :upcoming, -> { where("scheduled_at > ?", Time.current) }
  scope :past, -> { where("scheduled_at < ?", Time.current) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_property, ->(property) { where(property: property) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(scheduled_at: :desc) }
  scope :today, -> { where(scheduled_at: Date.current.beginning_of_day..Date.current.end_of_day) }

  def past?
    scheduled_at < Time.current
  end

  def upcoming?
    scheduled_at > Time.current
  end

  def can_be_cancelled?
    pending? && upcoming? && scheduled_at > Time.current + 2.hours
  end

  def can_be_rescheduled?
    (pending? || confirmed?) && upcoming?
  end

  def formatted_date_time
    scheduled_at.strftime("%A, %B %d, %Y at %l:%M %p")
  end
end
