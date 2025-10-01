require "test_helper"

class NotificationServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @landlord = create(:user, role: "landlord", name: "John Landlord", email: "landlord@example.com")
    @tenant = create(:user, role: "tenant", name: "Jane Tenant", email: "tenant@example.com")
    @contractor = create(:user, role: "landlord", name: "Bob Contractor", email: "contractor@example.com")
    @property = create(:property, user: @landlord, price: 2000)

    # Create active lease agreement for tenant - required for maintenance requests
    @lease_agreement = create(:lease_agreement, :active,
      property: @property,
      landlord: @landlord,
      tenant: @tenant
    )

    @maintenance_request = create(:maintenance_request,
      property: @property,
      tenant: @tenant,
      landlord: @landlord,
      priority: "medium",
      status: "pending",
      title: "Leaky faucet",
      description: "Kitchen faucet is dripping"
    )
  end

  test "should create notification for new maintenance request" do
    # Ensure no existing notifications for this maintenance request
    Notification.where(notifiable: @maintenance_request).destroy_all

    assert_difference "Notification.count", 1 do
      NotificationService.notify_new_maintenance_request(@maintenance_request)
    end

    notification = Notification.last
    assert_equal @landlord, notification.user
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
    assert_equal "maintenance_request_status_change", notification.notification_type
    assert_includes notification.title, "Maintenance Request Updated"
    assert_includes notification.message, "In progress"  # status.humanize capitalizes
  end

  test "should create notification when maintenance request is assigned" do
    @maintenance_request.update!(assigned_to: @contractor)

    assert_difference "Notification.count", 2 do # One for tenant, one for contractor
      notifications = NotificationService.notify_maintenance_assignment(@maintenance_request)
      assert_equal 2, notifications.length
    end

    tenant_notification = Notification.where(user: @tenant).last
    contractor_notification = Notification.where(user: @contractor).last

    assert_equal "maintenance_request_assigned", tenant_notification.notification_type
    assert_equal "maintenance_request_assigned", contractor_notification.notification_type
    assert_includes tenant_notification.message, "assigned to"
    assert_includes contractor_notification.message, "You have been assigned"
  end

  test "should create notification when maintenance request is completed" do
    @maintenance_request.update!(status: "completed", completed_at: Time.current)

    assert_difference "Notification.count", 1 do
      notification = NotificationService.notify_maintenance_completion(@maintenance_request)
      assert notification.present?
    end

    notification = Notification.last
    assert_equal @tenant, notification.user
    assert_equal "maintenance_request_completed", notification.notification_type
    assert_includes notification.title, "Maintenance Request Completed"
  end

  test "should not create duplicate notifications" do
    # Ensure no existing notifications
    Notification.where(notifiable: @maintenance_request).destroy_all

    # Create initial notification
    first_notification = NotificationService.notify_new_maintenance_request(@maintenance_request)
    assert_not_nil first_notification

    # Try to create same notification again - should return nil without creating
    assert_no_difference "Notification.count" do
      duplicate = NotificationService.notify_new_maintenance_request(@maintenance_request)
      assert_nil duplicate
    end
  end

  test "should handle missing users gracefully" do
    # Create a new maintenance request without saving to avoid validation
    invalid_request = MaintenanceRequest.new(
      property: @property,
      tenant: nil, # Missing tenant
      landlord: @landlord,
      priority: "medium",
      status: "pending",
      title: "Test",
      description: "Test description"
    )

    assert_no_difference "Notification.count" do
      result = NotificationService.notify_new_maintenance_request(invalid_request)
      assert_nil result
    end
  end

  test "should create email notification job for urgent requests" do
    # Ensure no existing notifications
    Notification.where(notifiable: @maintenance_request).destroy_all

    @maintenance_request.update!(priority: "emergency")

    assert_enqueued_jobs 1, only: NotificationEmailJob do
      NotificationService.notify_new_maintenance_request(@maintenance_request)
    end
  end
end
