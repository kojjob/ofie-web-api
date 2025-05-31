require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  def setup
    @landlord = users(:landlord)
    @tenant = users(:tenant)
    @property = properties(:property_one)
    @conversation = conversations(:conversation_one)
  end

  test "should be valid with valid attributes" do
    # Clean up any existing conversations to avoid uniqueness conflicts
    Conversation.where(landlord: @landlord, tenant: @tenant, property: @property).destroy_all

    conversation = Conversation.new(
      landlord: @landlord,
      tenant: @tenant,
      property: @property,
      subject: "Test conversation",
      status: "active"
    )
    assert conversation.valid?
  end

  test "should require landlord" do
    conversation = Conversation.new(
      tenant: @tenant,
      property: @property,
      subject: "Test conversation"
    )
    assert_not conversation.valid?
    assert_includes conversation.errors[:landlord], "must exist"
  end

  test "should require tenant" do
    conversation = Conversation.new(
      landlord: @landlord,
      property: @property,
      subject: "Test conversation"
    )
    assert_not conversation.valid?
    assert_includes conversation.errors[:tenant], "must exist"
  end

  test "should require property" do
    conversation = Conversation.new(
      landlord: @landlord,
      tenant: @tenant,
      subject: "Test conversation"
    )
    assert_not conversation.valid?
    assert_includes conversation.errors[:property], "must exist"
  end

  test "should require subject" do
    conversation = Conversation.new(
      landlord: @landlord,
      tenant: @tenant,
      property: @property
    )
    assert_not conversation.valid?
    assert_includes conversation.errors[:subject], "can't be blank"
  end

  test "should enforce uniqueness of landlord, tenant, and property combination" do
    # Clean up any existing conversations
    Conversation.where(landlord: @landlord, tenant: @tenant, property: @property).destroy_all

    # Create first conversation
    conversation1 = Conversation.create!(
      landlord: @landlord,
      tenant: @tenant,
      property: @property,
      subject: "First conversation"
    )

    # Try to create duplicate
    conversation2 = Conversation.new(
      landlord: @landlord,
      tenant: @tenant,
      property: @property,
      subject: "Second conversation"
    )

    assert_not conversation2.valid?
    assert_includes conversation2.errors[:landlord_id], "has already been taken"
  end

  test "should have default status of active" do
    conversation = Conversation.new(
      landlord: @landlord,
      tenant: @tenant,
      property: @property,
      subject: "Test conversation"
    )
    assert_equal "active", conversation.status
  end

  test "should return other participant for landlord" do
    assert_equal @tenant, @conversation.other_participant(@landlord)
  end

  test "should return other participant for tenant" do
    assert_equal @landlord, @conversation.other_participant(@tenant)
  end

  test "should return nil for non-participant" do
    other_user = users(:another_tenant)
    assert_nil @conversation.other_participant(other_user)
  end

  test "should count unread messages for user" do
    # Clean up existing messages to get accurate counts
    @conversation.messages.destroy_all

    # Create some messages
    message1 = Message.create!(
      conversation: @conversation,
      sender: @landlord,
      content: "Hello",
      read: false
    )
    message2 = Message.create!(
      conversation: @conversation,
      sender: @landlord,
      content: "How are you?",
      read: false
    )

    assert_equal 2, @conversation.unread_count_for(@tenant)
    assert_equal 0, @conversation.unread_count_for(@landlord)
  end

  test "should mark messages as read for user" do
    # Create unread messages
    message1 = Message.create!(
      conversation: @conversation,
      sender: @landlord,
      content: "Hello",
      read: false
    )
    message2 = Message.create!(
      conversation: @conversation,
      sender: @landlord,
      content: "How are you?",
      read: false
    )

    @conversation.mark_as_read_for(@tenant)

    message1.reload
    message2.reload

    assert message1.read?
    assert message2.read?
  end

  test "should update last message time" do
    original_time = @conversation.last_message_at
    sleep 0.01 # Ensure time difference

    @conversation.update_last_message_time!

    assert @conversation.last_message_at > original_time
  end

  test "active scope should return active conversations" do
    # Clean up existing conversations to avoid uniqueness conflicts
    Conversation.destroy_all

    active_conversation = Conversation.create!(
      landlord: @landlord,
      tenant: users(:another_tenant),
      property: properties(:property_two),
      subject: "Active conversation",
      status: "active"
    )

    archived_conversation = Conversation.create!(
      landlord: users(:another_landlord),
      tenant: users(:another_tenant),
      property: @property,
      subject: "Archived conversation",
      status: "archived"
    )

    active_conversations = Conversation.active
    assert_includes active_conversations, active_conversation
    assert_not_includes active_conversations, archived_conversation
  end

  test "for_user scope should return conversations for user" do
    user_conversations = Conversation.for_user(@landlord)
    assert_includes user_conversations, @conversation

    other_user = users(:another_tenant)
    other_conversations = Conversation.for_user(other_user)
    assert_not_includes other_conversations, @conversation
  end
end
