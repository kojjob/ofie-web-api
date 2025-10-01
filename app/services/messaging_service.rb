class MessagingService
  class << self
    # Create a new conversation between users about a property
    def create_conversation(landlord:, tenant:, property:, subject: nil, initial_message: nil)
      # Check if conversation already exists
      existing_conversation = Conversation.find_by(
        landlord: landlord,
        tenant: tenant,
        property: property
      )

      if existing_conversation
        return { success: false, error: "Conversation already exists", conversation: existing_conversation }
      end

      # Validate users can message each other
      unless can_users_message?(landlord, tenant, property)
        return { success: false, error: "Users cannot message each other about this property" }
      end

      conversation = nil
      Message.transaction do
        # Create conversation
        conversation = Conversation.create!(
          landlord: landlord,
          tenant: tenant,
          property: property,
          subject: subject || "Inquiry about #{property.title}",
          status: "active"
        )

        # Create initial message if provided
        if initial_message.present?
          Message.create!(
            conversation: conversation,
            sender: tenant,
            content: initial_message,
            message_type: "text"
          )
        end

        # Send notification email to landlord
        MessageMailer.conversation_started_notification(conversation).deliver_later
      end

      { success: true, conversation: conversation }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message }
    end

    # Send a message in an existing conversation
    def send_message(conversation:, sender:, content:, message_type: "text", attachment_url: nil)
      # Validate sender is part of conversation
      unless conversation_participant?(conversation, sender)
        return { success: false, error: "User is not part of this conversation" }
      end

      # Validate conversation is active
      unless conversation.status == "active"
        return { success: false, error: "Conversation is not active" }
      end

      message = nil
      Message.transaction do
        message = Message.create!(
          conversation: conversation,
          sender: sender,
          content: content,
          message_type: message_type,
          attachment_url: attachment_url
        )

        # Update conversation timestamp
        conversation.update!(last_message_at: Time.current)

        # Send notification email to recipient
        MessageMailer.new_message_notification(message).deliver_later
      end

      { success: true, message: message }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message }
    end

    # Mark messages as read for a user
    def mark_messages_as_read(conversation:, user:, message_ids: nil)
      unless conversation_participant?(conversation, user)
        return { success: false, error: "User is not part of this conversation" }
      end

      messages = conversation.messages
      messages = messages.where(id: message_ids) if message_ids.present?
      messages = messages.where.not(sender: user) # Don't mark own messages as read

      updated_count = messages.where(read: false).update_all(
        read: true,
        read_at: Time.current
      )

      { success: true, updated_count: updated_count }
    end

    # Get conversation statistics for a user
    def conversation_stats(user:)
      conversations = user.conversations
      {
        total_conversations: conversations.count,
        active_conversations: conversations.active.count,
        unread_messages: user.unread_messages_count,
        recent_conversations: conversations.recent.limit(5)
      }
    end

    # Archive/close a conversation
    def archive_conversation(conversation:, user:)
      unless conversation_participant?(conversation, user)
        return { success: false, error: "User is not part of this conversation" }
      end

      conversation.update!(status: "archived")
      { success: true, conversation: conversation }
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message }
    end

    private

    # Check if two users can message each other about a property
    def can_users_message?(landlord, tenant, property)
      # Landlord must own the property
      return false unless property.user_id == landlord.id

      # Users must have different roles
      return false if landlord.id == tenant.id

      true
    end

    # Check if user is participant in conversation
    def conversation_participant?(conversation, user)
      conversation.landlord_id == user.id || conversation.tenant_id == user.id
    end
  end
end
