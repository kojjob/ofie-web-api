class PropertyReview < ApplicationRecord
  belongs_to :user
  belongs_to :property

  validates :rating, presence: true, inclusion: { in: 1..5, message: "Rating must be between 1 and 5" }
  validates :title, presence: true, length: { maximum: 100 }
  validates :content, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :user_id, uniqueness: { scope: :property_id, message: "You can only review a property once" }

  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :recent, -> { order(created_at: :desc) }
  scope :most_helpful, -> { order(helpful_count: :desc) }
  scope :for_property, ->(property) { where(property: property) }
  scope :for_user, ->(user) { where(user: user) }

  def self.average_rating
    average(:rating)&.round(1) || 0.0
  end

  def self.rating_distribution
    group(:rating).count
  end

  def increment_helpful_count!
    increment!(:helpful_count)
  end

  def verify!
    update!(verified: true)
  end

  def unverify!
    update!(verified: false)
  end
end
