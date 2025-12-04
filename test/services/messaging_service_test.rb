require "test_helper"

class MessagingServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @landlord = create(:user, role: "landlord", name: "John Landlord", email: "landlord@example.com")
    @tenant = create(:user, role: "tenant", name: "Jane Tenant", email: "tenant@example.com")
    @property = create(:property, user: @landlord, title: "Cozy Apartment", price: 2000)
  end

  # ============================================================================
  # CREATE_CONVERSATION TESTS
  # ============================================================================

  test "should create new conversation with initial message" do
    assert_difference [ "Conversation.count", "Message.count" ], 1 do
      result = MessagingService.create_conversation(
        landlord: @landlord,
        tenant: @tenant,
        property: @property,
        subject: "Property Inquiry",
        initial_message: "Is this property still available?"
      )

      assert result[:success]
      assert_instance_of Conversation, result[:conversation]
      assert_equal "Property Inquiry", result[:conversation].subject
    end

    conversation = Conversation.last
    assert_equal @landlord, conversation.landlord
    assert_equal @tenant, conversation.tenant
    assert_equal @property, conversation.property
    assert_equal "active", conversation.status

    message = Message.last
    assert_equal conversation, message.conversation
    assert_equal @tenant, message.sender
    assert_equal "Is this property still available?", message.content
    assert_equal "text", message.message_type
  end

  test "should create conversation with default subject when none provided" do
    result = MessagingService.create_conversation(
      landlord: @landlord,
      tenant: @tenant,
      property: @property
    )

    assert result[:success]
    assert_equal "Inquiry about #{@property.title}", result[:conversation].subject
  end

  test "should create conversation without initial message" do
    assert_difference "Conversation.count", 1 do
      assert_no_difference "Message.count" do
        result = MessagingService.create_conversation(
          landlord: @landlord,
          tenant: @tenant,
          property: @property
        )

        assert result[:success]
      end
    end
  end

  test "should not create duplicate conversation" do
    # Create first conversation
    MessagingService.create_conversation(
      landlord: @landlord,
      tenant: @tenant,
      property: @property
    )

    # Try to create duplicate
    assert_no_difference "Conversation.count" do
      result = MessagingService.create_conversation(
        landlord: @landlord,
        tenant: @tenant,
        property: @property
      )

      assert_not result[:success]
      assert_equal "Conversation already exists", result[:error]
      assert_instance_of Conversation, result[:conversation]
    end
  end

  test "should not create conversation if landlord doesn't own property" do
    other_landlord = create(:user, role: "landlord", name: "Other Landlord")

    result = MessagingService.create_conversation(
      landlord: other_landlord,
      tenant: @tenant,
      property: @property
    )

    assert_not result[:success]
    assert_equal "Users cannot message each other about this property", result[:error]
  end

  test "should not create conversation if users are the same" do
    result = MessagingService.create_conversation(
      landlord: @landlord,
      tenant: @landlord,
      property: @property
    )

    assert_not result[:success]
    assert_equal "Users cannot message each other about this property", result[:error]
  end


  test "should enqueue conversation started email" do
    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      MessagingService.create_conversation(
        landlord: @landlord,
        tenant: @tenant,
        property: @property
      )
    end
  end

  # ============================================================================
  # SEND_MESSAGE TESTS
  # ============================================================================

  test "should send message in active conversation" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    assert_difference "Message.count", 1 do
      result = MessagingService.send_message(
        conversation: conversation,
        sender: @tenant,
        content: "Can I schedule a viewing?"
      )

      assert result[:success]
      assert_instance_of Message, result[:message]
    end

    message = Message.last
    assert_equal conversation, message.conversation
    assert_equal @tenant, message.sender
    assert_equal "Can I schedule a viewing?", message.content
    assert_equal "text", message.message_type

    # Check conversation timestamp updated
    conversation.reload
    assert_not_nil conversation.last_message_at
  end

  test "should send message with attachment" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    result = MessagingService.send_message(
      conversation: conversation,
      sender: @landlord,
      content: "Here are the documents",
      message_type: "file",
      attachment_url: "https://example.com/docs/lease.pdf"
    )

    assert result[:success]
    message = result[:message]
    assert_equal "file", message.message_type
    assert_equal "https://example.com/docs/lease.pdf", message.attachment_url
  end

  test "should not send message if sender is not participant" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)
    other_user = create(:user, role: "tenant", name: "Other Tenant")

    result = MessagingService.send_message(
      conversation: conversation,
      sender: other_user,
      content: "Hello"
    )

    assert_not result[:success]
    assert_equal "User is not part of this conversation", result[:error]
  end

  test "should not send message if conversation is not active" do
    conversation = create(:conversation, :archived, landlord: @landlord, tenant: @tenant, property: @property)

    result = MessagingService.send_message(
      conversation: conversation,
      sender: @tenant,
      content: "Hello"
    )

    assert_not result[:success]
    assert_equal "Conversation is not active", result[:error]
  end

  test "should enqueue new message email" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
      MessagingService.send_message(
        conversation: conversation,
        sender: @tenant,
        content: "Hello"
      )
    end
  end

  # ============================================================================
  # MARK_MESSAGES_AS_READ TESTS
  # ============================================================================

  test "should mark all unread messages as read for user" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    # Create messages from landlord (tenant hasn't read them)
    message1 = create(:message, conversation: conversation, sender: @landlord, content: "Message 1", read: false)
    message2 = create(:message, conversation: conversation, sender: @landlord, content: "Message 2", read: false)
    # Create message from tenant (should not be marked as read)
    message3 = create(:message, conversation: conversation, sender: @tenant, content: "Message 3", read: false)

    result = MessagingService.mark_messages_as_read(
      conversation: conversation,
      user: @tenant
    )

    assert result[:success]
    assert_equal 2, result[:updated_count]

    message1.reload
    message2.reload
    message3.reload

    assert message1.read
    assert message2.read
    assert_not message3.read
  end

  test "should mark specific messages as read" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    message1 = create(:message, conversation: conversation, sender: @landlord, content: "Message 1", read: false)
    message2 = create(:message, conversation: conversation, sender: @landlord, content: "Message 2", read: false)

    result = MessagingService.mark_messages_as_read(
      conversation: conversation,
      user: @tenant,
      message_ids: [ message1.id ]
    )

    assert result[:success]
    assert_equal 1, result[:updated_count]

    message1.reload
    message2.reload

    assert message1.read
    assert_not message2.read
  end

  test "should not mark own messages as read" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    message = create(:message, conversation: conversation, sender: @tenant, content: "My message", read: false)

    result = MessagingService.mark_messages_as_read(
      conversation: conversation,
      user: @tenant
    )

    assert result[:success]
    assert_equal 0, result[:updated_count]

    message.reload
    assert_not message.read
  end

  test "should not mark messages as read if user is not participant" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)
    other_user = create(:user, role: "tenant", name: "Other Tenant")

    result = MessagingService.mark_messages_as_read(
      conversation: conversation,
      user: other_user
    )

    assert_not result[:success]
    assert_equal "User is not part of this conversation", result[:error]
  end

  # ============================================================================
  # CONVERSATION_STATS TESTS
  # ============================================================================

  test "should return conversation statistics for user" do
    # Create active conversation
    conversation1 = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    # Create archived conversation with different property
    other_property = create(:property, user: @landlord, title: "Other Property")
    conversation2 = create(:conversation, :archived, landlord: @landlord, tenant: @tenant, property: other_property)

    # Create some messages
    create(:message, conversation: conversation1, sender: @tenant, content: "Message 1")
    create(:message, conversation: conversation1, sender: @landlord, content: "Message 2", read: false)

    stats = MessagingService.conversation_stats(user: @tenant)

    assert_equal 2, stats[:total_conversations]
    assert_equal 1, stats[:active_conversations]
    assert stats[:recent_conversations].present?
  end

  # ============================================================================
  # ARCHIVE_CONVERSATION TESTS
  # ============================================================================

  test "should archive conversation" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)

    result = MessagingService.archive_conversation(
      conversation: conversation,
      user: @landlord
    )

    assert result[:success]
    assert_equal "archived", result[:conversation].status
  end

  test "should not archive conversation if user is not participant" do
    conversation = create(:conversation, landlord: @landlord, tenant: @tenant, property: @property)
    other_user = create(:user, role: "tenant", name: "Other Tenant")

    result = MessagingService.archive_conversation(
      conversation: conversation,
      user: other_user
    )

    assert_not result[:success]
    assert_equal "User is not part of this conversation", result[:error]
  end
end
