require "test_helper"

class NavbarNotificationsAuthenticationTest < ActionDispatch::IntegrationTest
  test "notifications controller should not load when user is not authenticated" do
    get blog_path
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

    # Sign in the user (you may need to adjust this based on your authentication method)
    post login_path, params: { email: user.email, password: "password123" }

    get blog_path
    assert_response :success

    # Verify that the notifications controller div is present
    assert_select "div[data-controller='notifications']", count: 1
  end

  test "blog posts should load without notification polling errors when not authenticated" do
    # Create a test blog post
    user = User.create!(
      email: "author@example.com",
      password: "password123",
      name: "Author User",
      role: "landlord"
    )

    blog_post = Blog.create!(
      title: "Test Blog Post",
      slug: "test-blog-post",
      content: "This is a test blog post",
      excerpt: "Test excerpt",
      status: "published",
      user: user
    )

    # Visit the blog post without authentication
    get blog_path(blog_post)
    assert_response :success

    # Verify that the notifications controller div is not present
    assert_select "div[data-controller='notifications']", count: 0
  end
end
