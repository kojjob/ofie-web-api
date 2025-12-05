class PropertyInquiry < ApplicationRecord
  belongs_to :property
  belongs_to :user, optional: true

  # Enums
  enum :status, {
    pending: 0,
    read: 1,
    responded: 2,
    archived: 3
  }, default: :pending

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :phone, length: { maximum: 20 }, allow_blank: true

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_property, ->(property_id) { where(property_id: property_id) }
  scope :for_landlord, ->(user_id) { joins(:property).where(properties: { user_id: user_id }) }

  # Callbacks
  before_create :set_defaults

  # Instance methods
  def mark_as_read!
    update!(read_at: Time.current, status: :read)
  end

  def mark_as_responded!
    update!(status: :responded)
  end

  def archive!
    update!(status: :archived)
  end

  def unread?
    read_at.nil?
  end

  private

  def set_defaults
    self.status ||= :pending
  end
end
