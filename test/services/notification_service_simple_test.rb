require "test_helper"

class NotificationServiceSimpleTest < ActiveSupport::TestCase
  def setup
    @landlord = User.create!(
      email: "test_landlord@example.com",
      password: "password123",
      role: "landlord",
      name: "Test Landlord",
      email_verified: true
    )

    @tenant = User.create!(
      email: "test_tenant@example.com",
      password: "password123",
      role: "tenant",
      name: "Test Tenant",
      email_verified: true
    )

    @property = Property.create!(
      title: "Test Property",
      description: "A test property",
      address: "123 Test Street",
      city: "Test City",
      price: 1000.00,
      bedrooms: 2,
      bathrooms: 1.0,
      square_feet: 800,
      property_type: "apartment",
      availability_status: "available",
      status: "active",
      user: @landlord
    )

    @maintenance_request = MaintenanceRequest.create!(
      property: @property,
      tenant: @tenant,
      title: "Test Maintenance Request",
      description: "A test maintenance request",
      priority: "medium",
      status: "pending",
      category: "plumbing"
    )
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
  end

  test "should create notification for status change" do
    old_status = @maintenance_request.status
    @maintenance_request.update!(status: "in_progress")

    assert_difference "Notification.count", 1 do
      NotificationService.notify_maintenance_status_change(@maintenance_request, old_status)
    end

    notification = Notification.last
    assert_equal @tenant, notification.user
    assert_equal @maintenance_request, notification.notifiable
    assert_equal "maintenance_request_status_change", notification.notification_type
    assert_includes notification.title, "Status Updated"
  end
end
