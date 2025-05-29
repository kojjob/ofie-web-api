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

  validates :scheduled_at, presence: true
  validates :status, presence: true
  validates :scheduled_at, comparison: { greater_than: Time.current }, on: :create
  validates :contact_phone, format: { with: /\A[\+]?[1-9]?[0-9]{7,15}\z/, message: "Invalid phone format" }, allow_blank: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :upcoming, -> { where("scheduled_at > ?", Time.current) }
  scope :past, -> { where("scheduled_at < ?", Time.current) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_property, ->(property) { where(property: property) }
  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(scheduled_at: :desc) }

  def past?
    scheduled_at < Time.current
  end

  def upcoming?
    scheduled_at > Time.current
  end

  def can_be_cancelled?
    pending? && upcoming?
  end
end
