require "test_helper"

class PropertyCommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @property = properties(:one)
    @comment = PropertyComment.new(
      user: @user,
      property: @property,
      content: "This is a test comment about the property."
    )
  end

  test "should be valid with valid attributes" do
    assert @comment.valid?
  end

  test "should require content" do
    @comment.content = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:content], "can't be blank"
  end

  test "should require content to be at least 1 character" do
    @comment.content = ""
    assert_not @comment.valid?
  end

  test "should not allow content longer than 2000 characters" do
    @comment.content = "a" * 2001
    assert_not @comment.valid?
  end

  test "should require user" do
    @comment.user = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:user], "must exist"
  end

  test "should require property" do
    @comment.property = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:property], "must exist"
  end

  test "should be top level by default" do
    @comment.save!
    assert @comment.top_level?
    assert_not @comment.reply?
  end

  test "should allow replies to top level comments" do
    @comment.save!

    reply = PropertyComment.new(
      user: users(:two),
      property: @property,
      content: "This is a reply to the comment.",
      parent: @comment
    )

    assert reply.valid?
    reply.save!

    assert reply.reply?
    assert_not reply.top_level?
    assert_equal @comment, reply.parent
    assert_includes @comment.replies, reply
  end

  test "should not allow replies to replies" do
    @comment.save!

    reply = PropertyComment.create!(
      user: users(:two),
      property: @property,
      content: "This is a reply to the comment.",
      parent: @comment
    )

    reply_to_reply = PropertyComment.new(
      user: @user,
      property: @property,
      content: "This is a reply to a reply.",
      parent: reply
    )

    assert_not reply_to_reply.valid?
    assert_includes reply_to_reply.errors[:parent], "cannot be a reply to another reply"
  end

  test "should require parent to belong to same property" do
    other_property = Property.create!(
      title: "Other Property",
      description: "Another property",
      price: 1000,
      bedrooms: 1,
      bathrooms: 1,
      address: "456 Other St",
      city: "Other City",
      state: "OS",
      zip_code: "54321",
      user: users(:two)
    )

    @comment.save!

    reply = PropertyComment.new(
      user: users(:two),
      property: other_property,
      content: "This is a reply to a comment on a different property.",
      parent: @comment
    )

    assert_not reply.valid?
    assert_includes reply.errors[:parent], "must belong to the same property"
  end

  test "should track likes count" do
    @comment.save!
    assert_equal 0, @comment.likes_count

    # Create a like
    like = CommentLike.create!(user: users(:two), property_comment: @comment)
    @comment.reload
    assert_equal 1, @comment.likes_count

    # Remove the like
    like.destroy!
    @comment.reload
    assert_equal 0, @comment.likes_count
  end

  test "should toggle likes correctly" do
    @comment.save!
    user = users(:two)

    # Like the comment
    result = @comment.toggle_like!(user)
    assert result # should return true for liked
    assert_equal 1, @comment.likes_count
    assert @comment.liked_by?(user)

    # Unlike the comment
    result = @comment.toggle_like!(user)
    assert_not result # should return false for unliked
    assert_equal 0, @comment.likes_count
    assert_not @comment.liked_by?(user)
  end

  test "should flag and unflag comments" do
    @comment.save!

    assert_not @comment.flagged?

    @comment.flag!("Inappropriate content", users(:two))
    assert @comment.flagged?
    assert_equal "Inappropriate content", @comment.flagged_reason
    assert_not_nil @comment.flagged_at

    @comment.unflag!
    assert_not @comment.flagged?
    assert_nil @comment.flagged_reason
    assert_nil @comment.flagged_at
  end

  test "should display flagged content appropriately" do
    @comment.save!

    assert_equal @comment.content, @comment.display_content

    @comment.flag!("Inappropriate content")
    assert_equal "[This comment has been flagged and is under review]", @comment.display_content
  end

  test "should check edit permissions correctly" do
    @comment.save!

    # Owner can edit within 15 minutes
    assert @comment.can_be_edited_by?(@user)

    # Other users cannot edit
    assert_not @comment.can_be_edited_by?(users(:two))

    # Owner cannot edit after 15 minutes
    @comment.update!(created_at: 20.minutes.ago)
    assert_not @comment.can_be_edited_by?(@user)
  end

  test "should check delete permissions correctly" do
    @comment.save!

    # Owner can delete
    assert @comment.can_be_deleted_by?(@user)

    # Property owner can delete
    assert @comment.can_be_deleted_by?(@property.user)

    # Other users cannot delete
    assert_not @comment.can_be_deleted_by?(users(:two))
  end
end
