class Property < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  enum :property_type, { apartment: 0, house: 1, condo: 2, townhouse: 3 }
  enum :availability_status, { available: 0, rented: 1 }

  validates :title, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :bedrooms, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bathrooms, presence: true, numericality: { greater_than: 0 }
  validates :property_type, presence: true
  validates :availability_status, presence: true

  scope :available, -> { where(availability_status: "available") }
  scope :by_city, ->(city) { where(city: city) if city.present? }
  scope :by_property_type, ->(type) { where(property_type: type) if type.present? }
  scope :by_bedrooms, ->(bedrooms) { where(bedrooms: bedrooms) if bedrooms.present? }
  scope :by_bathrooms, ->(bathrooms) { where(bathrooms: bathrooms) if bathrooms.present? }
  scope :by_price_range, ->(min_price, max_price) {
    scope = all
    scope = scope.where("price >= ?", min_price) if min_price.present?
    scope = scope.where("price <= ?", max_price) if max_price.present?
    scope
  }
end
