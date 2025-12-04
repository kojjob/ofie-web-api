require "test_helper"

class NavbarNotificationsAuthenticationTest < ActionDispatch::IntegrationTest
  test "notifications controller should not load when user is not authenticated" do
    get home_path
    assert_response :success

    # Verify that the notifications controller div is not present
    assert_select "div[data-controller='notifications']", count: 0
  end

  test "notifications controller should load when user is authenticated" do
    user = User.create!(
      email: "test@example.com",
      password: "password123",
      name: "Test User",
      role: "tenant"
    )

    # Sign in the user
    post login_path, params: { email: user.email, password: "password123" }
    follow_redirect!

    get home_path
    assert_response :success

    # Verify that the notifications controller div is present
    assert_select "div[data-controller='notifications']", count: 1
  end

  test "public pages should load without notification polling errors when not authenticated" do
    # Visit public page without authentication
    get about_path
    assert_response :success

    # Verify that the notifications controller div is not present
    assert_select "div[data-controller='notifications']", count: 0
  end
end
