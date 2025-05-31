class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :title, presence: true
  validates :message, presence: true
  validates :notification_type, presence: true

  scope :unread, -> { where(read: false) }
  scope :read, -> { where(read: true) }
  scope :recent, -> { order(created_at: :desc) }

  # Notification types
  TYPES = [
    "favorite",
    "message",
    "booking",
    "property_update",
    "review",
    "system",
    "comment",
    "comment_flagged",
    "property",
    "payment",
    "maintenance_request_new",
    "maintenance_request_status_change",
    "maintenance_request_assigned",
    "maintenance_request_completed"
  ].freeze

  validates :notification_type, inclusion: { in: TYPES }

  # Class methods for creating specific notification types
  class << self
    def create_favorite_notification(user, property)
      create!(
        user: property.user,
        notifiable: property,
        title: "Property Favorited",
        message: "#{user.name || user.email} added your property '#{property.title}' to their favorites",
        notification_type: "favorite",
        url: "/properties/#{property.id}"
      )
    end

    def create_message_notification(recipient, sender, message_content)
      create!(
        user: recipient,
        title: "New Message",
        message: "#{sender.name || sender.email}: #{message_content.truncate(50)}",
        notification_type: "message",
        url: "/messages"
      )
    end

    def create_booking_notification(landlord, property, tenant)
      create!(
        user: landlord,
        notifiable: property,
        title: "New Booking Request",
        message: "#{tenant.name || tenant.email} requested to book '#{property.title}'",
        notification_type: "booking",
        url: "/properties/#{property.id}/bookings"
      )
    end

    def create_property_update_notification(user, property)
      create!(
        user: user,
        notifiable: property,
        title: "Property Updated",
        message: "Your property '#{property.title}' has been updated",
        notification_type: "property_update",
        url: "/properties/#{property.id}"
      )
    end

    def create_review_notification(landlord, property, reviewer)
      create!(
        user: landlord,
        notifiable: property,
        title: "New Review",
        message: "#{reviewer.name || reviewer.email} left a review for '#{property.title}'",
        notification_type: "review",
        url: "/properties/#{property.id}#reviews"
      )
    end

    def create_system_notification(user, title, message, url = nil)
      create!(
        user: user,
        title: title,
        message: message,
        notification_type: "system",
        url: url
      )
    end

    def create_maintenance_request_notification(user, maintenance_request, type, title, message)
      create!(
        user: user,
        notifiable: maintenance_request,
        title: title,
        message: message,
        notification_type: type,
        url: "/maintenance_requests/#{maintenance_request.id}"
      )
    end
  end

  # Instance methods
  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end

  def mark_as_unread!
    update!(read: false, read_at: nil)
  end

  def read?
    read
  end

  def unread?
    !read
  end

  def time_ago
    time_diff = Time.current - created_at

    case time_diff
    when 0..59
      "Just now"
    when 60..3599
      "#{(time_diff / 60).to_i}m ago"
    when 3600..86399
      "#{(time_diff / 3600).to_i}h ago"
    when 86400..604799
      "#{(time_diff / 86400).to_i}d ago"
    else
      created_at.strftime("%b %d, %Y")
    end
  end
end
