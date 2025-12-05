require "test_helper"

class BlogControllerTest < ActionDispatch::IntegrationTest
  # Load fixtures
  fixtures :users, :posts

  # ==========================================================
  # SETUP
  # ==========================================================
  def setup
    @landlord = users(:landlord)
    @another_landlord = users(:another_landlord)
    @tenant = users(:tenant)
    @published_post = posts(:published_post)
    @featured_post = posts(:featured_post)
    @draft_post = posts(:draft_post)
    @scheduled_post = posts(:scheduled_post)
  end

  # Login helper for web session-based authentication
  # Note: Don't follow_redirect! - session is already set after the POST
  def login_as(user)
    post login_url, params: { email: user.email, password: "password123" }
  end

  # ==========================================================
  # INDEX ACTION (Public)
  # ==========================================================
  test "should get index without authentication" do
    get blog_index_url
    assert_response :success
  end

  test "index shows only published posts" do
    get blog_index_url
    assert_response :success

    # Should show published posts
    assert_match @published_post.title, response.body

    # Should not show draft posts
    assert_no_match(/#{Regexp.escape(@draft_post.title)}/, response.body)
  end

  test "index shows featured posts" do
    get blog_index_url
    assert_response :success
    assert_match @featured_post.title, response.body
  end

  test "index filters by category" do
    get blog_index_url, params: { category: "Tenant Guide" }
    assert_response :success

    # Should show Tenant Guide posts
    assert_match @published_post.title, response.body
  end

  test "index handles search query" do
    get blog_index_url, params: { search: "first-time" }
    assert_response :success
    assert_match @published_post.title, response.body
  end

  test "index handles pagination" do
    get blog_index_url, params: { page: 1 }
    assert_response :success
  end

  # ==========================================================
  # SHOW ACTION (Public)
  # ==========================================================
  test "should get show for published post without authentication" do
    get blog_post_url(@published_post.slug)
    assert_response :success
    assert_match @published_post.title, response.body
  end

  test "show increments views count" do
    initial_views = @published_post.views_count
    get blog_post_url(@published_post.slug)
    assert_response :success
    @published_post.reload
    assert_equal initial_views + 1, @published_post.views_count
  end

  test "show displays related posts" do
    get blog_post_url(@published_post.slug)
    assert_response :success
  end

  test "show redirects for non-existent slug" do
    # Note: ErrorHandler redirects HTML requests instead of returning 404 status
    get blog_post_url("non-existent-slug")
    assert_response :redirect
  end

  # ==========================================================
  # NEW ACTION (Authenticated)
  # ==========================================================
  test "should redirect new when not authenticated" do
    get new_blog_post_url
    assert_response :redirect
  end

  test "should get new when authenticated" do
    login_as(@landlord)
    get new_blog_post_url
    assert_response :success
  end

  # ==========================================================
  # CREATE ACTION (Authenticated)
  # ==========================================================
  test "should redirect create when not authenticated" do
    post blog_index_url, params: { post: { title: "Test Post" } }
    assert_response :redirect
  end

  test "should create post when authenticated" do
    login_as(@landlord)

    assert_difference("Post.count") do
      post blog_index_url, params: {
        post: {
          title: "My New Blog Post",
          category: "Property Tips",
          excerpt: "A short excerpt",
          tags: "test, new",
          published: false
        }
      }
    end

    created_post = Post.find_by(title: "My New Blog Post")
    assert_not_nil created_post
    assert_redirected_to blog_post_url(created_post.slug)
  end

  test "create fails with invalid params" do
    login_as(@landlord)

    assert_no_difference("Post.count") do
      post blog_index_url, params: {
        post: {
          title: "",
          category: ""
        }
      }
    end

    assert_response :unprocessable_entity
  end

  # ==========================================================
  # EDIT ACTION (Authenticated + Authorized)
  # ==========================================================
  test "should redirect edit when not authenticated" do
    get edit_blog_post_url(@published_post.slug)
    assert_response :redirect
  end

  test "should get edit for own post" do
    login_as(@landlord)
    get edit_blog_post_url(@published_post.slug)
    assert_response :success
  end

  test "should redirect edit for other user's post as tenant" do
    login_as(@tenant)
    get edit_blog_post_url(@published_post.slug)
    assert_redirected_to blog_index_url
  end

  test "landlord can edit any post" do
    login_as(@landlord)
    other_post = posts(:other_author_post)
    get edit_blog_post_url(other_post.slug)
    assert_response :success
  end

  # ==========================================================
  # UPDATE ACTION (Authenticated + Authorized)
  # ==========================================================
  test "should redirect update when not authenticated" do
    patch blog_post_url(@published_post.slug), params: { post: { title: "Updated" } }
    assert_response :redirect
  end

  test "should update own post" do
    login_as(@landlord)

    patch blog_post_url(@published_post.slug), params: {
      post: {
        title: "Updated Post Title"
      }
    }

    assert_redirected_to blog_post_url(@published_post.reload.slug)
    assert_equal "Updated Post Title", @published_post.title
  end

  test "update handles remove_featured_image parameter" do
    login_as(@landlord)

    patch blog_post_url(@published_post.slug), params: {
      post: {
        title: @published_post.title,
        remove_featured_image: "1"
      }
    }

    assert_redirected_to blog_post_url(@published_post.slug)
  end

  test "update fails with invalid params" do
    login_as(@landlord)

    patch blog_post_url(@published_post.slug), params: {
      post: {
        title: "",
        category: ""
      }
    }

    assert_response :unprocessable_entity
  end

  # ==========================================================
  # DESTROY ACTION (Authenticated + Authorized)
  # ==========================================================
  test "should redirect destroy when not authenticated" do
    delete destroy_blog_post_url(@published_post.slug)
    assert_response :redirect
  end

  test "should destroy own post" do
    login_as(@landlord)

    assert_difference("Post.count", -1) do
      delete destroy_blog_post_url(@published_post.slug)
    end

    assert_redirected_to blog_index_url
  end

  test "should not destroy other user's post as tenant" do
    login_as(@tenant)

    assert_no_difference("Post.count") do
      delete destroy_blog_post_url(@published_post.slug)
    end

    assert_redirected_to blog_index_url
  end
end
