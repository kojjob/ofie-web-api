class Property < ApplicationRecord
  include Cacheable

  belongs_to :user
  has_many_attached :photos

  # Lease associations
  has_many :lease_agreements, dependent: :destroy
  has_many :rental_applications, dependent: :destroy

  # New associations for property features
  has_many :property_favorites, dependent: :destroy
  has_many :favorited_by_users, through: :property_favorites, source: :user
  has_many :property_viewings, dependent: :destroy
  has_many :property_reviews, dependent: :destroy
  has_many :property_comments, dependent: :destroy
  has_many :maintenance_requests, dependent: :destroy
  has_many :conversations, dependent: :destroy

  # Define property types as an enum for easy management and validation
  enum :property_type, {
    apartment: "apartment",
    house: "house",
    condo: "condo",
    townhouse: "townhouse",
    studio: "studio",
    loft: "loft"
  }

  # Define availability status as an enum
  enum :availability_status, {
    available: 0,
    rented: 1,
    pending: 2,
    maintenance: 3
  }

  # Define property status as an enum (new feature)
  attribute :status, :integer, default: 0
  enum :status, {
    active: 0,
    inactive: 1,
    draft: 2,
    archived: 3
  }, prefix: true

  validates :title, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 2000 }
  validates :address, presence: true
  validates :city, presence: true
  # validates :state, presence: true
  # validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/, message: "Invalid ZIP code format" }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :bedrooms, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bathrooms, presence: true, numericality: { greater_than: 0 }
  validates :square_feet, numericality: { greater_than: 0 }, allow_nil: true
  validates :property_type, presence: true, inclusion: { in: property_types.keys }
  validates :availability_status, presence: true

  # Scopes for filtering
  scope :available, -> { where(availability_status: :available) }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_state, ->(state) { where(state: state) if state.present? }
  scope :by_property_type, ->(type) { where(property_type: type) if type.present? }
  scope :by_bedrooms, ->(count) { where(bedrooms: count) if count.present? }
  scope :by_bathrooms, ->(count) { where(bathrooms: count) if count.present? }
  scope :by_price_range, ->(min, max) { where(price: min..max) if min.present? && max.present? }
  scope :price_range, ->(min, max) { where(price: min..max) }
  scope :min_bedrooms, ->(count) { where("bedrooms >= ?", count) }
  scope :min_bathrooms, ->(count) { where("bathrooms >= ?", count) }
  scope :recent, -> { order(created_at: :desc) }

  # New scopes for enhanced features
  scope :with_parking, -> { where(parking_available: true) }
  scope :pet_friendly, -> { where(pets_allowed: true) }
  scope :furnished, -> { where(furnished: true) }
  scope :utilities_included, -> { where(utilities_included: true) }
  scope :with_amenity, ->(amenity) { where(amenity => true) }
  scope :favorited_by, ->(user) { joins(:property_favorites).where(property_favorites: { user: user }) }

  # Instance methods for property features
  def favorited_by?(user)
    return false unless user
    property_favorites.exists?(user: user)
  end

  def favorites_count
    property_favorites.count
  end

  def average_rating
    property_reviews.average(:rating)&.round(1) || 0.0
  end

  def reviews_count
    property_reviews.count
  end

  def available_for_applications?
    available? && status_active?
  end

  def verified_reviews
    property_reviews.verified
  end

  def upcoming_viewings
    property_viewings.upcoming
  end

  def amenities_list
    amenities = []
    amenities << "Parking" if parking_available?
    amenities << "Pet Friendly" if pets_allowed?
    amenities << "Furnished" if furnished?
    amenities << "Utilities Included" if utilities_included?
    amenities << "Laundry" if laundry?
    amenities << "Gym" if gym?
    amenities << "Pool" if pool?
    amenities << "Balcony" if balcony?
    amenities << "Air Conditioning" if air_conditioning?
    amenities << "Heating" if heating?
    amenities << "Internet Included" if internet_included?
    amenities
  end

  def comments_count
    property_comments.not_flagged.count
  end

  def recent_comments(limit = 5)
    property_comments.not_flagged.includes(:user, :replies).top_level.recent.limit(limit)
  end

  # Helper method for full address
  def full_address
    parts = [address, city, state, zip_code].compact.reject(&:blank?)
    parts.join(", ")
  end

  # Check if property is available
  def available?
    availability_status == "available"
  end
end
