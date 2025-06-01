require "test_helper"

class NotificationServiceTest < ActiveSupport::TestCase
  def setup
    @landlord = users(:landlord)
    @tenant = users(:tenant)
    @property = properties(:property_one)
    @maintenance_request = maintenance_requests(:pending_request)
  end

  test "should create notification for new maintenance request" do
    assert_difference "Notification.count", 1 do
      NotificationService.notify_new_maintenance_request(@maintenance_request)
    end

    notification = Notification.last
    assert_equal @landlord, notification.user
    assert_equal @maintenance_request, notification.notifiable
    assert_equal "maintenance_request_new", notification.notification_type
    assert_includes notification.title, "New Maintenance Request"
    assert_includes notification.message, @tenant.name || @tenant.email
    assert_includes notification.url, "/maintenance_requests/#{@maintenance_request.id}"
  end

  test "should create notification for maintenance request status change" do
    old_status = @maintenance_request.status
    @maintenance_request.update!(status: "in_progress")

    assert_difference "Notification.count", 1 do
      NotificationService.notify_maintenance_status_change(@maintenance_request, old_status)
    end

    notification = Notification.last
    assert_equal @tenant, notification.user
    assert_equal @maintenance_request, notification.notifiable
    assert_equal "maintenance_request_status_change", notification.notification_type
    assert_includes notification.title, "Maintenance Request Updated"
    assert_includes notification.message, "in_progress"
  end

  test "should create notification when maintenance request is assigned" do
    contractor = users(:contractor)
    @maintenance_request.update!(assigned_to: contractor)

    assert_difference "Notification.count", 2 do # One for tenant, one for contractor
      NotificationService.notify_maintenance_assignment(@maintenance_request)
    end

    tenant_notification = Notification.where(user: @tenant).last
    contractor_notification = Notification.where(user: contractor).last

    assert_equal "maintenance_request_assigned", tenant_notification.notification_type
    assert_equal "maintenance_request_assigned", contractor_notification.notification_type
    assert_includes tenant_notification.message, "assigned to"
    assert_includes contractor_notification.message, "You have been assigned"
  end

  test "should create notification when maintenance request is completed" do
    @maintenance_request.update!(status: "completed", completed_at: Time.current)

    assert_difference "Notification.count", 1 do
      NotificationService.notify_maintenance_completion(@maintenance_request)
    end

    notification = Notification.last
    assert_equal @tenant, notification.user
    assert_equal "maintenance_request_completed", notification.notification_type
    assert_includes notification.title, "Maintenance Request Completed"
  end

  test "should not create duplicate notifications" do
    # Create initial notification
    NotificationService.notify_new_maintenance_request(@maintenance_request)
    initial_count = Notification.count

    # Try to create same notification again
    assert_no_difference "Notification.count" do
      NotificationService.notify_new_maintenance_request(@maintenance_request)
    end
  end

  test "should handle missing users gracefully" do
    @maintenance_request.tenant = nil

    assert_no_difference "Notification.count" do
      NotificationService.notify_new_maintenance_request(@maintenance_request)
    end
  end

  test "should create email notification job for urgent requests" do
    @maintenance_request.update!(priority: "emergency")

    assert_enqueued_with(job: NotificationEmailJob) do
      NotificationService.notify_new_maintenance_request(@maintenance_request)
    end
  end
end
