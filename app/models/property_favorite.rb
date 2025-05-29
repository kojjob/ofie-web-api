class PropertyFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :property

  validates :user_id, uniqueness: { scope: :property_id, message: "Property already favorited" }

  scope :for_user, ->(user) { where(user: user) }
  scope :for_property, ->(property) { where(property: property) }
  scope :recent, -> { order(created_at: :desc) }
end
