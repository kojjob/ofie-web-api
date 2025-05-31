# Service class for handling notification creation and delivery
# Follows single responsibility principle and keeps models clean
class NotificationService
  class << self
    # Creates notification for new maintenance request
    # Notifies the landlord when a tenant creates a new maintenance request
    def notify_new_maintenance_request(maintenance_request)
      return unless maintenance_request&.landlord && maintenance_request&.tenant

      # Check for duplicate notification
      existing = Notification.find_by(
        user: maintenance_request.landlord,
        notifiable: maintenance_request,
        notification_type: "maintenance_request_new"
      )
      return if existing

      notification = Notification.create!(
        user: maintenance_request.landlord,
        notifiable: maintenance_request,
        title: "New Maintenance Request",
        message: build_new_request_message(maintenance_request),
        notification_type: "maintenance_request_new",
        url: "/maintenance_requests/#{maintenance_request.id}"
      )

      # Send email for urgent requests
      if urgent_priority?(maintenance_request.priority)
        NotificationEmailJob.perform_later(notification)
      end

      # Broadcast real-time update
      broadcast_notification(notification)

      notification
    end

    # Creates notification for maintenance request status changes
    # Notifies the tenant when status changes
    def notify_maintenance_status_change(maintenance_request, old_status = nil)
      return unless maintenance_request&.tenant
      return if maintenance_request.status == old_status

      notification = Notification.create!(
        user: maintenance_request.tenant,
        notifiable: maintenance_request,
        title: "Maintenance Request Updated",
        message: build_status_change_message(maintenance_request, old_status),
        notification_type: "maintenance_request_status_change",
        url: "/maintenance_requests/#{maintenance_request.id}"
      )

      # Send email for important status changes
      if important_status_change?(maintenance_request.status)
        NotificationEmailJob.perform_later(notification)
      end

      broadcast_notification(notification)
      notification
    end

    # Creates notifications when maintenance request is assigned
    # Notifies both tenant and assigned contractor
    def notify_maintenance_assignment(maintenance_request)
      return unless maintenance_request&.assigned_to

      notifications = []

      # Notify tenant
      if maintenance_request.tenant
        tenant_notification = Notification.create!(
          user: maintenance_request.tenant,
          notifiable: maintenance_request,
          title: "Maintenance Request Assigned",
          message: build_assignment_message_for_tenant(maintenance_request),
          notification_type: "maintenance_request_assigned",
          url: "/maintenance_requests/#{maintenance_request.id}"
        )
        notifications << tenant_notification
        broadcast_notification(tenant_notification)
      end

      # Notify assigned contractor
      contractor_notification = Notification.create!(
        user: maintenance_request.assigned_to,
        notifiable: maintenance_request,
        title: "New Assignment",
        message: build_assignment_message_for_contractor(maintenance_request),
        notification_type: "maintenance_request_assigned",
        url: "/maintenance_requests/#{maintenance_request.id}"
      )
      notifications << contractor_notification
      broadcast_notification(contractor_notification)

      # Send email to contractor
      NotificationEmailJob.perform_later(contractor_notification)

      notifications
    end

    # Creates notification when maintenance request is completed
    # Notifies the tenant
    def notify_maintenance_completion(maintenance_request)
      return unless maintenance_request&.tenant
      return unless maintenance_request.completed?

      notification = Notification.create!(
        user: maintenance_request.tenant,
        notifiable: maintenance_request,
        title: "Maintenance Request Completed",
        message: build_completion_message(maintenance_request),
        notification_type: "maintenance_request_completed",
        url: "/maintenance_requests/#{maintenance_request.id}"
      )

      NotificationEmailJob.perform_later(notification)
      broadcast_notification(notification)
      notification
    end

    private

    def build_new_request_message(maintenance_request)
      tenant_name = maintenance_request.tenant.name || maintenance_request.tenant.email
      property_title = maintenance_request.property.title
      "#{tenant_name} submitted a #{maintenance_request.priority} priority maintenance request for '#{property_title}': #{maintenance_request.title}"
    end

    def build_status_change_message(maintenance_request, old_status)
      status_text = maintenance_request.status.humanize
      property_title = maintenance_request.property.title
      message = "Your maintenance request for '#{property_title}' has been updated to #{status_text}"

      if maintenance_request.scheduled_at && maintenance_request.scheduled?
        message += " and is scheduled for #{maintenance_request.scheduled_at.strftime('%B %d, %Y at %I:%M %p')}"
      end

      message
    end

    def build_assignment_message_for_tenant(maintenance_request)
      assigned_name = maintenance_request.assigned_to.name || "a contractor"
      property_title = maintenance_request.property.title
      "Your maintenance request for '#{property_title}' has been assigned to #{assigned_name}"
    end

    def build_assignment_message_for_contractor(maintenance_request)
      property_title = maintenance_request.property.title
      "You have been assigned a #{maintenance_request.priority} priority maintenance request for '#{property_title}': #{maintenance_request.title}"
    end

    def build_completion_message(maintenance_request)
      property_title = maintenance_request.property.title
      "Your maintenance request for '#{property_title}' has been completed. #{maintenance_request.completion_notes if maintenance_request.completion_notes.present?}"
    end

    def urgent_priority?(priority)
      %w[emergency high].include?(priority)
    end

    def important_status_change?(status)
      %w[in_progress scheduled completed].include?(status)
    end

    def broadcast_notification(notification)
      # Broadcast to user's notification stream for real-time updates
      Turbo::StreamsChannel.broadcast_prepend_to(
        "notifications_#{notification.user.id}",
        target: "notifications-list",
        partial: "notifications/notification",
        locals: { notification: notification }
      )

      # Update notification count
      Turbo::StreamsChannel.broadcast_update_to(
        "notifications_#{notification.user.id}",
        target: "notification-count",
        html: notification.user.notifications.unread.count.to_s
      )
    end
  end
end
