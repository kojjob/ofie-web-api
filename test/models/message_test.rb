require "test_helper"

class MessageTest < ActiveSupport::TestCase
  def setup
    @landlord = create(:user, :landlord, :verified)
    @tenant = create(:user, :tenant, :verified)
    @property = create(:property, user: @landlord)
    @conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)
    @sender = @landlord
    @recipient = @tenant
  end

  test "should be valid with valid attributes" do
    message = Message.new(
      conversation: @conversation,
      sender: @sender,
      content: "Hello, how are you?",
      message_type: "text"
    )
    assert message.valid?
  end

  test "should require conversation" do
    message = Message.new(
      sender: @sender,
      content: "Hello"
    )
    assert_not message.valid?
    assert_includes message.errors[:conversation], "must exist"
  end

  test "should require sender" do
    message = Message.new(
      conversation: @conversation,
      content: "Hello"
    )
    assert_not message.valid?
    assert_includes message.errors[:sender], "must exist"
  end

  test "should require content" do
    message = Message.new(
      conversation: @conversation,
      sender: @sender
    )
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "should have default message_type of text" do
    message = Message.new(
      conversation: @conversation,
      sender: @sender,
      content: "Hello"
    )
    assert_equal "text", message.message_type
  end

  test "should have default read status of false" do
    message = Message.new(
      conversation: @conversation,
      sender: @sender,
      content: "Hello"
    )
    assert_equal false, message.read
  end

  test "should validate message_type inclusion" do
    message = Message.new(
      conversation: @conversation,
      sender: @sender,
      content: "Hello",
      message_type: "invalid_type"
    )
    assert_not message.valid?
    assert_includes message.errors[:message_type], "is not included in the list"
  end

  test "should accept valid message types" do
    valid_types = %w[text image file]

    valid_types.each do |type|
      message = Message.new(
        conversation: @conversation,
        sender: @sender,
        content: "Test content",
        message_type: type
      )
      assert message.valid?, "Message with type '#{type}' should be valid"
    end
  end

  test "should return correct recipient" do
    # Message from landlord to tenant
    message = Message.create!(
      conversation: @conversation,
      sender: @conversation.landlord,
      content: "Hello tenant"
    )
    assert_equal @conversation.tenant, message.recipient

    # Message from tenant to landlord
    message2 = Message.create!(
      conversation: @conversation,
      sender: @conversation.tenant,
      content: "Hello landlord"
    )
    assert_equal @conversation.landlord, message2.recipient
  end

  test "should mark message as read" do
    message = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "Hello",
      read: false
    )

    assert_not message.read?

    message.mark_as_read!

    assert message.read?
    assert_not_nil message.read_at
  end

  test "should not mark already read message" do
    message = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "Hello",
      read: true,
      read_at: 1.hour.ago
    )

    original_read_at = message.read_at
    message.mark_as_read!

    assert_equal original_read_at.to_i, message.read_at.to_i
  end

  test "unread scope should return unread messages" do
    read_message = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "Read message",
      read: true
    )

    unread_message = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "Unread message",
      read: false
    )

    unread_messages = Message.unread
    assert_includes unread_messages, unread_message
    assert_not_includes unread_messages, read_message
  end

  test "recent scope should return messages in descending order" do
    # Clear existing messages to avoid fixture interference
    Message.delete_all

    old_message = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "Old message",
      created_at: 2.hours.ago
    )

    new_message = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "New message",
      created_at: 1.hour.ago
    )

    recent_messages = Message.recent
    assert_equal new_message, recent_messages.first
    assert_equal old_message, recent_messages.second
  end

  test "for_conversation scope should return messages for specific conversation" do
    other_landlord = create(:user, :landlord, :verified)
    other_tenant = create(:user, :tenant, :verified)
    other_property = create(:property, user: other_landlord)
    other_conversation = create(:conversation, landlord: other_landlord, tenant: other_tenant, property: other_property)

    message_in_conversation = Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "Message in target conversation"
    )

    message_in_other = Message.create!(
      conversation: other_conversation,
      sender: other_landlord,
      content: "Message in other conversation"
    )

    conversation_messages = Message.for_conversation(@conversation)
    assert_includes conversation_messages, message_in_conversation
    assert_not_includes conversation_messages, message_in_other
  end

  test "should update conversation timestamp after create" do
    original_time = @conversation.last_message_at
    sleep 0.01 # Ensure time difference

    Message.create!(
      conversation: @conversation,
      sender: @sender,
      content: "New message"
    )

    @conversation.reload
    assert @conversation.last_message_at > original_time
  end
end
