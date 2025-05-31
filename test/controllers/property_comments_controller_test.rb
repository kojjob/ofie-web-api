require "test_helper"

class PropertyCommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @property = properties(:one)
    @comment = property_comments(:one)
  end

  test "should get index without authentication" do
    get property_property_comments_path(@property)
    assert_response :success
    assert_select "h3", "Discussion"
  end

  test "should show sign in message when not authenticated" do
    get property_property_comments_path(@property)
    assert_response :success
    assert_select "p", "Sign in to join the discussion"
  end

  test "should create comment when authenticated" do
    # Simulate login by setting session
    post login_path, params: { 
      user: { 
        email: @user.email, 
        password: "password123" 
      } 
    }
    
    assert_difference("PropertyComment.count") do
      post property_property_comments_path(@property), params: {
        property_comment: {
          content: "This is a test comment from the integration test."
        }
      }
    end
    
    assert_redirected_to property_property_comments_path(@property)
    follow_redirect!
    assert_match "Comment was successfully posted", response.body
  end

  test "should not create comment without content" do
    # Simulate login
    post login_path, params: { 
      user: { 
        email: @user.email, 
        password: "password123" 
      } 
    }
    
    assert_no_difference("PropertyComment.count") do
      post property_property_comments_path(@property), params: {
        property_comment: {
          content: ""
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should not create comment when not authenticated" do
    assert_no_difference("PropertyComment.count") do
      post property_property_comments_path(@property), params: {
        property_comment: {
          content: "This should not be created"
        }
      }
    end
    
    assert_redirected_to login_path
  end

  test "should toggle like when authenticated" do
    # Simulate login
    post login_path, params: { 
      user: { 
        email: @user.email, 
        password: "password123" 
      } 
    }
    
    # Like the comment
    assert_difference("CommentLike.count") do
      post toggle_like_property_comment_path(@comment)
    end
    
    # Unlike the comment
    assert_difference("CommentLike.count", -1) do
      post toggle_like_property_comment_path(@comment)
    end
  end

  test "should flag comment when authenticated" do
    # Simulate login with different user
    other_user = users(:two)
    post login_path, params: { 
      user: { 
        email: other_user.email, 
        password: "password123" 
      } 
    }
    
    post flag_property_comment_path(@comment), params: {
      reason: "Test flagging"
    }
    
    @comment.reload
    assert @comment.flagged?
    assert_equal "Test flagging", @comment.flagged_reason
  end

  test "should delete comment when owner" do
    # Simulate login as comment owner
    post login_path, params: { 
      user: { 
        email: @comment.user.email, 
        password: "password123" 
      } 
    }
    
    assert_difference("PropertyComment.count", -1) do
      delete property_comment_path(@comment)
    end
    
    assert_redirected_to property_property_comments_path(@comment.property)
  end

  test "should not delete comment when not owner" do
    # Simulate login as different user
    other_user = users(:two)
    post login_path, params: { 
      user: { 
        email: other_user.email, 
        password: "password123" 
      } 
    }
    
    assert_no_difference("PropertyComment.count") do
      delete property_comment_path(@comment)
    end
    
    # Should redirect back with error
    assert_response :redirect
  end

  test "should create reply to comment" do
    # Simulate login
    post login_path, params: { 
      user: { 
        email: @user.email, 
        password: "password123" 
      } 
    }
    
    assert_difference("PropertyComment.count") do
      post property_property_comments_path(@property), params: {
        property_comment: {
          content: "This is a reply to the comment.",
          parent_id: @comment.id
        }
      }
    end
    
    reply = PropertyComment.last
    assert_equal @comment, reply.parent
    assert_equal @property, reply.property
    assert reply.reply?
  end

  test "should not allow reply to reply" do
    # Create a reply first
    reply = PropertyComment.create!(
      user: @user,
      property: @property,
      content: "This is a reply",
      parent: @comment
    )
    
    # Simulate login
    post login_path, params: { 
      user: { 
        email: @user.email, 
        password: "password123" 
      } 
    }
    
    # Try to reply to the reply
    assert_no_difference("PropertyComment.count") do
      post property_property_comments_path(@property), params: {
        property_comment: {
          content: "This should not be allowed",
          parent_id: reply.id
        }
      }
    end
    
    assert_response :unprocessable_entity
  end
end
