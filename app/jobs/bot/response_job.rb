# Background job for processing bot responses asynchronously
class Bot::ResponseJob < ApplicationJob
  queue_as :bot_responses

  def perform(conversation_id, user_message_id)
    conversation = Conversation.find(conversation_id)
    user_message = Message.find(user_message_id)

    # Ensure this is a bot conversation
    return unless conversation.landlord.bot?

    # Add typing indicator
    broadcast_typing_start(conversation)

    begin
      # Initialize bot engine with conversation context
      bot_engine = Bot::IntelligentBotEngine.new(
        user: conversation.tenant,
        conversation: conversation,
        context: build_conversation_context(conversation)
      )

      # Process the user message
      bot_response = bot_engine.process_message(user_message.content)

      # Simulate realistic typing delay for better UX
      sleep([ bot_response[:typing_delay] / 1000.0, 3.0 ].min)

      # Create bot message
      bot_message = create_bot_message(conversation, bot_response)

      # Stop typing indicator
      broadcast_typing_stop(conversation)

      # Broadcast bot response
      broadcast_bot_response(conversation, bot_message, bot_response)

      # Handle special actions
      handle_special_actions(conversation, bot_response)

      # Update conversation metadata
      update_conversation_metadata(conversation, bot_response)

    rescue StandardError => e
      Rails.logger.error "Bot response generation failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Stop typing and send error message
      broadcast_typing_stop(conversation)
      broadcast_error_response(conversation)
    end
  end

  private

  def build_conversation_context(conversation)
    {
      property: conversation.property,
      conversation_history: conversation.messages.order(created_at: :desc).limit(10),
      user_profile: build_user_profile(conversation.tenant),
      conversation_metadata: conversation.metadata || {}
    }
  end

  def build_user_profile(user)
    {
      role: user.role,
      account_age: Time.current - user.created_at,
      properties_count: user.landlord? ? user.properties.count : 0,
      applications_count: user.tenant? ? user.tenant_rental_applications.count : 0,
      recent_activity: analyze_recent_activity(user)
    }
  end

  def analyze_recent_activity(user)
    recent_cutoff = 7.days.ago

    {
      messages_sent: user.sent_messages.where("created_at > ?", recent_cutoff).count,
      properties_viewed: user.tenant? ? user.property_viewings.where("created_at > ?", recent_cutoff).count : 0,
      applications_submitted: user.tenant? ? user.tenant_rental_applications.where("created_at > ?", recent_cutoff).count : 0
    }
  end

  def create_bot_message(conversation, bot_response)
    bot_user = Bot.primary_bot

    Message.create!(
      conversation: conversation,
      sender: bot_user,
      content: bot_response[:response],
      message_type: "text",
      metadata: {
        intent: bot_response[:intent],
        confidence: bot_response[:confidence],
        entities: bot_response[:entities],
        smart_actions: bot_response[:smart_actions],
        generation_time: Time.current
      }
    )
  end

  def broadcast_typing_start(conversation)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "typing_indicator",
        data: {
          user_id: Bot.primary_bot.id,
          user_name: Bot.primary_bot.name,
          action: "start",
          timestamp: Time.current
        }
      }
    )
  end

  def broadcast_typing_stop(conversation)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "typing_indicator",
        data: {
          user_id: Bot.primary_bot.id,
          user_name: Bot.primary_bot.name,
          action: "stop",
          timestamp: Time.current
        }
      }
    )
  end

  def broadcast_bot_response(conversation, bot_message, bot_response)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "bot_response",
        data: {
          message: serialize_message(bot_message),
          smart_actions: bot_response[:smart_actions],
          conversation_suggestions: bot_response[:conversation_suggestions],
          media_attachments: bot_response[:media_attachments],
          requires_human_handoff: bot_response[:requires_human_handoff],
          timestamp: Time.current
        }
      }
    )
  end

  def broadcast_error_response(conversation)
    error_message = create_error_message(conversation)

    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "bot_error",
        data: {
          message: serialize_message(error_message),
          error_type: "processing_error",
          timestamp: Time.current
        }
      }
    )
  end

  def create_error_message(conversation)
    bot_user = Bot.primary_bot

    Message.create!(
      conversation: conversation,
      sender: bot_user,
      content: "I'm having a bit of trouble processing that request right now. Could you try rephrasing your question, or would you like me to connect you with a human agent? 🤖",
      message_type: "text",
      metadata: {
        is_error_message: true,
        error_timestamp: Time.current
      }
    )
  end

  def handle_special_actions(conversation, bot_response)
    # Handle human handoff request
    if bot_response[:requires_human_handoff]
      schedule_human_handoff(conversation, bot_response[:intent])
    end

    # Schedule follow-up if needed
    if should_schedule_followup?(bot_response)
      schedule_followup_message(conversation, bot_response)
    end

    # Trigger property recommendations if searching
    if bot_response[:intent] == :property_search_advanced
      Bot::PropertyRecommendationJob.perform_later(conversation.tenant.id, bot_response[:entities])
    end
  end

  def update_conversation_metadata(conversation, bot_response)
    metadata = conversation.metadata || {}

    metadata[:last_bot_intent] = bot_response[:intent]
    metadata[:last_bot_confidence] = bot_response[:confidence]
    metadata[:bot_interaction_count] = (metadata[:bot_interaction_count] || 0) + 1
    metadata[:last_bot_response_at] = Time.current

    conversation.update!(metadata: metadata)
  end

  def schedule_human_handoff(conversation, intent)
    # Create notification for support team
    NotificationService.notify_human_handoff_needed(conversation, intent)

    # Schedule follow-up if no human responds within timeframe
    Bot::FollowupJob.set(wait: 30.minutes).perform_later(
      conversation.id,
      "human_handoff_followup"
    )
  end

  def should_schedule_followup?(bot_response)
    follow_up_intents = [
      :application_guidance,
      :maintenance_intelligent,
      :property_search_advanced
    ]

    follow_up_intents.include?(bot_response[:intent]) && bot_response[:confidence] > 0.7
  end

  def schedule_followup_message(conversation, bot_response)
    # Schedule appropriate follow-up based on intent
    delay = case bot_response[:intent]
    when :property_search_advanced
      1.day
    when :application_guidance
      3.days
    when :maintenance_intelligent
      1.day
    else
      2.days
    end

    Bot::FollowupJob.set(wait: delay).perform_later(
      conversation.id,
      bot_response[:intent].to_s
    )
  end

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      sender_avatar: message.sender.avatar.attached? ? rails_blob_url(message.sender.avatar) : nil,
      sender_role: message.sender.role,
      message_type: message.message_type,
      created_at: message.created_at,
      metadata: message.metadata
    }
  end
end
