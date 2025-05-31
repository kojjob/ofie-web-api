# Background job for sending email notifications
# Keeps the main request fast by handling email delivery asynchronously
class NotificationEmailJob < ApplicationJob
  queue_as :default

  def perform(notification)
    return unless notification.is_a?(Notification)
    return unless notification.user&.email

    # Send email based on notification type
    case notification.notification_type
    when "maintenance_request_new"
      NotificationMailer.maintenance_request_created(notification).deliver_now
    when "maintenance_request_status_change"
      NotificationMailer.maintenance_request_updated(notification).deliver_now
    when "maintenance_request_assigned"
      NotificationMailer.maintenance_request_assigned(notification).deliver_now
    when "maintenance_request_completed"
      NotificationMailer.maintenance_request_completed(notification).deliver_now
    when "rental_application_new"
      NotificationMailer.rental_application_received(notification).deliver_now
    when "rental_application_status_change"
      NotificationMailer.rental_application_status_updated(notification).deliver_now
    when "rental_application_updated"
      NotificationMailer.rental_application_updated(notification).deliver_now
    else
      NotificationMailer.generic_notification(notification).deliver_now
    end
  rescue StandardError => e
    Rails.logger.error "Failed to send notification email: #{e.message}"
    # Re-raise to trigger retry mechanism
    raise e
  end
end
