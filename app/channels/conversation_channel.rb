# Real-time conversation channel for instant bot responses
class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = find_conversation

    if conversation && authorized_for_conversation?(conversation)
      stream_from "conversation_#{conversation.id}"

      # Send presence update
      broadcast_presence_update(conversation, "joined")

      # Send conversation metadata
      transmit({
        type: "conversation_metadata",
        data: {
          conversation_id: conversation.id,
          participants: serialize_participants(conversation),
          unread_count: conversation.unread_count_for(current_user),
          last_activity: conversation.last_message_at
        }
      })
    else
      reject
    end
  end

  def unsubscribed
    conversation = find_conversation
    broadcast_presence_update(conversation, "left") if conversation
  end

  def receive(data)
    conversation = find_conversation
    return unless conversation && authorized_for_conversation?(conversation)

    case data["action"]
    when "send_message"
      handle_send_message(conversation, data)
    when "typing_start"
      handle_typing_indicator(conversation, data, "start")
    when "typing_stop"
      handle_typing_indicator(conversation, data, "stop")
    when "mark_read"
      handle_mark_read(conversation, data)
    when "request_suggestions"
      handle_request_suggestions(conversation)
    end
  end

  private

  def find_conversation
    @conversation ||= current_user.conversations.find_by(id: params[:conversation_id])
  end

  def authorized_for_conversation?(conversation)
    conversation.landlord == current_user || conversation.tenant == current_user
  end

  def handle_send_message(conversation, data)
    message_content = data["message"]
    return if message_content.blank?

    # Create user message
    user_message = Message.create!(
      conversation: conversation,
      sender: current_user,
      content: message_content,
      message_type: data["message_type"] || "text"
    )

    # Broadcast user message immediately
    broadcast_message(conversation, user_message, "new_message")

    # If this is a bot conversation, process bot response
    if conversation.landlord.bot?
      BotResponseJob.perform_later(conversation.id, user_message.id)
    end
  end

  def handle_typing_indicator(conversation, data, action)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "typing_indicator",
        data: {
          user_id: current_user.id,
          user_name: current_user.name,
          action: action,
          timestamp: Time.current
        }
      }
    )
  end

  def handle_mark_read(conversation, data)
    message_ids = data["message_ids"]

    if message_ids.present?
      messages = conversation.messages.where(id: message_ids)
      messages.where.not(sender: current_user).update_all(
        read: true,
        read_at: Time.current
      )
    else
      # Mark all unread messages as read
      conversation.mark_as_read_for(current_user)
    end

    # Broadcast read status update
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "messages_read",
        data: {
          reader_id: current_user.id,
          message_ids: message_ids || conversation.messages.where.not(sender: current_user).pluck(:id),
          timestamp: Time.current
        }
      }
    )
  end

  def handle_request_suggestions(conversation)
    # Generate contextual suggestions based on conversation
    suggestions = Bot::IntelligentBotEngine.new(
      user: current_user,
      conversation: conversation
    ).generate_proactive_suggestions

    transmit({
      type: "conversation_suggestions",
      data: {
        suggestions: suggestions,
        timestamp: Time.current
      }
    })
  end

  def broadcast_message(conversation, message, type)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: type,
        data: {
          message: serialize_message(message),
          conversation_id: conversation.id,
          timestamp: Time.current
        }
      }
    )
  end

  def broadcast_presence_update(conversation, action)
    return unless conversation

    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "presence_update",
        data: {
          user_id: current_user.id,
          user_name: current_user.name,
          action: action,
          timestamp: Time.current
        }
      }
    )
  end

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      sender_avatar: message.sender.avatar.attached? ? rails_blob_url(message.sender.avatar) : nil,
      message_type: message.message_type,
      created_at: message.created_at,
      read: message.read?,
      metadata: message.metadata
    }
  end

  def serialize_participants(conversation)
    [ conversation.landlord, conversation.tenant ].map do |participant|
      {
        id: participant.id,
        name: participant.name,
        role: participant.role,
        avatar: participant.avatar.attached? ? rails_blob_url(participant.avatar) : nil,
        online: participant.bot? ? true : user_online?(participant)
      }
    end
  end

  def user_online?(user)
    # Check if user has active connections
    ActionCable.server.connections.any? { |conn| conn.current_user == user }
  end
end
