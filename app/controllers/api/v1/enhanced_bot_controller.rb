# Enhanced API controller for intelligent bot interactions
class Api::V1::BotController < ApplicationController
  before_action :authenticate_request
  before_action :find_or_create_conversation, only: [ :send_message ]
  before_action :initialize_bot_engine, only: [ :send_message, :get_suggestions ]

  # Send message to bot and get intelligent response
  def send_message
    message_content = params[:message]

    if message_content.blank?
      return render json: { error: "Message content is required" }, status: :bad_request
    end

    begin
      # Process message through intelligent bot engine
      bot_response = @bot_engine.process_message(message_content)

      # Create message records
      user_message = create_user_message(message_content)
      bot_message = create_bot_message(bot_response)

      # Prepare response with rich data
      response_data = {
        conversation_id: @conversation.id,
        user_message: serialize_message(user_message),
        bot_response: {
          message: serialize_message(bot_message),
          intent: bot_response[:intent],
          confidence: bot_response[:confidence],
          entities: bot_response[:entities],
          smart_actions: bot_response[:smart_actions],
          conversation_suggestions: bot_response[:conversation_suggestions],
          typing_delay: bot_response[:typing_delay]
        },
        media_attachments: bot_response[:media_attachments],
        requires_human_handoff: bot_response[:requires_human_handoff]
      }

      # Send real-time updates if using ActionCable
      broadcast_message_update(response_data)

      render json: response_data, status: :ok

    rescue StandardError => e
      Rails.logger.error "Bot message processing failed: #{e.message}"

      # Fallback response
      fallback_response = create_fallback_response
      render json: {
        error: "Bot temporarily unavailable",
        fallback_response: fallback_response
      }, status: :service_unavailable
    end
  end

  # Get proactive suggestions for user
  def get_suggestions
    begin
      suggestions = @bot_engine.generate_proactive_suggestions

      render json: {
        suggestions: suggestions,
        timestamp: Time.current
      }, status: :ok

    rescue StandardError => e
      Rails.logger.error "Suggestion generation failed: #{e.message}"
      render json: { error: "Unable to generate suggestions" }, status: :service_unavailable
    end
  end

  # Get bot conversation starters
  def conversation_starters
    personality_engine = Bot::PersonalityEngine.new(user: current_user)

    starters = [
      personality_engine.get_conversation_starters,
      "What type of property are you looking for? 🏠",
      "Need help with a rental application? 📋",
      "Questions about maintenance or repairs? 🔧",
      "Want to learn about neighborhood amenities? 🏘️"
    ].flatten

    render json: {
      conversation_starters: starters.sample(4),
      greeting: personality_engine.get_greeting
    }, status: :ok
  end

  # Get bot analytics (for landlords/admins)
  def analytics
    unless current_user.landlord? || current_user.admin?
      return render json: { error: "Unauthorized" }, status: :forbidden
    end

    analytics_data = {
      user_interactions: Bot::LearningData.user_interaction_patterns(current_user.id),
      intent_accuracy: Bot::LearningData.intent_accuracy_report,
      improvement_opportunities: Bot::LearningData.improvement_opportunities,
      conversation_stats: get_conversation_stats
    }

    render json: analytics_data, status: :ok
  end

  # Mark conversation as requiring human support
  def request_human_support
    conversation_id = params[:conversation_id]
    reason = params[:reason] || "User requested human support"

    conversation = current_user.conversations.find(conversation_id)

    # Add metadata to conversation
    conversation.update!(
      metadata: (conversation.metadata || {}).merge({
        human_support_requested: true,
        human_support_reason: reason,
        human_support_requested_at: Time.current
      })
    )

    # Create notification for support team
    NotificationService.notify_human_support_requested(conversation, reason)

    render json: {
      message: "Human support has been requested",
      conversation_id: conversation.id,
      estimated_response_time: "15-30 minutes during business hours"
    }, status: :ok
  end

  # Get bot personality insights
  def personality_profile
    personality_engine = Bot::PersonalityEngine.new(user: current_user)

    profile = {
      communication_style: personality_engine.communication_style,
      personality_traits: personality_engine.personality_traits,
      user_expertise_level: determine_user_expertise,
      interaction_preferences: get_interaction_preferences,
      personalization_data: get_personalization_data
    }

    render json: profile, status: :ok
  end

  # Provide feedback on bot response
  def feedback
    message_id = params[:message_id]
    feedback_type = params[:feedback_type] # 'helpful', 'not_helpful', 'inaccurate'
    feedback_details = params[:details]

    message = Message.find(message_id)

    # Store feedback for bot improvement
    BotFeedback.create!(
      user: current_user,
      message: message,
      feedback_type: feedback_type,
      details: feedback_details,
      context: extract_feedback_context(message)
    )

    render json: { message: "Thank you for your feedback!" }, status: :ok
  end

  private

  def find_or_create_conversation
    property_id = params[:property_id]

    if property_id
      property = Property.find(property_id)
      @conversation = find_or_create_property_conversation(property)
    else
      @conversation = find_or_create_general_conversation
    end
  end

  def find_or_create_property_conversation(property)
    bot_user = Bot.primary_bot

    # Find existing conversation about this property
    existing_conversation = Conversation.find_by(
      tenant: current_user,
      landlord: bot_user,
      property: property
    )

    return existing_conversation if existing_conversation

    # Create new conversation
    Conversation.create!(
      tenant: current_user,
      landlord: bot_user,
      property: property,
      subject: "Questions about #{property.title}",
      status: "active"
    )
  end

  def find_or_create_general_conversation
    bot_user = Bot.primary_bot

    # Find existing general conversation
    existing_conversation = current_user.conversations
      .where(landlord: bot_user, property: nil)
      .where("created_at > ?", 30.days.ago)
      .first

    return existing_conversation if existing_conversation

    # Create new general conversation
    Conversation.create!(
      tenant: current_user,
      landlord: bot_user,
      property: nil,
      subject: "General Assistance",
      status: "active"
    )
  end

  def initialize_bot_engine
    @bot_engine = Bot::IntelligentBotEngine.new(
      user: current_user,
      conversation: @conversation,
      context: build_conversation_context
    )
  end

  def build_conversation_context
    {
      property: @conversation&.property,
      recent_activity: get_user_recent_activity,
      user_preferences: get_user_preferences,
      conversation_history: get_conversation_history
    }
  end

  def create_user_message(content)
    Message.create!(
      conversation: @conversation,
      sender: current_user,
      content: content,
      message_type: "text"
    )
  end

  def create_bot_message(bot_response)
    bot_user = Bot.primary_bot

    Message.create!(
      conversation: @conversation,
      sender: bot_user,
      content: bot_response[:response],
      message_type: "text",
      metadata: {
        intent: bot_response[:intent],
        confidence: bot_response[:confidence],
        entities: bot_response[:entities],
        smart_actions: bot_response[:smart_actions]
      }
    )
  end

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      sender_type: message.sender.role,
      created_at: message.created_at,
      metadata: message.metadata
    }
  end

  def broadcast_message_update(response_data)
    # Broadcast to conversation channel for real-time updates
    ActionCable.server.broadcast(
      "conversation_#{@conversation.id}",
      {
        type: "new_message",
        data: response_data
      }
    )
  rescue StandardError => e
    Rails.logger.error "Broadcast failed: #{e.message}"
  end

  def create_fallback_response
    "I'm experiencing some technical difficulties right now. Please try again in a moment, or contact our support team if you need immediate assistance."
  end

  def get_conversation_stats
    {
      total_conversations: current_user.conversations.count,
      bot_conversations: current_user.conversations.joins(:landlord).where(users: { role: "bot" }).count,
      average_response_time: calculate_average_response_time,
      satisfaction_rating: calculate_satisfaction_rating
    }
  end

  def determine_user_expertise
    # Determine user's expertise level based on their activity
    if current_user.created_at > 1.week.ago
      "beginner"
    elsif current_user.tenant_rental_applications.count > 3
      "experienced"
    else
      "intermediate"
    end
  end

  def get_interaction_preferences
    # Analyze user's preferred interaction style
    {
      prefers_detailed_responses: determine_detail_preference,
      prefers_quick_actions: determine_action_preference,
      communication_time_preference: determine_time_preference
    }
  end

  def get_personalization_data
    {
      recent_searches: get_recent_searches,
      preferred_property_types: get_preferred_property_types,
      budget_range: get_budget_range,
      location_preferences: get_location_preferences
    }
  end

  def extract_feedback_context(message)
    {
      intent: message.metadata&.dig("intent"),
      confidence: message.metadata&.dig("confidence"),
      conversation_length: @conversation.messages.count,
      user_expertise: determine_user_expertise,
      response_time: Time.current - message.created_at
    }
  end

  # Helper methods for analytics and preferences
  def calculate_average_response_time
    # Calculate average time between user message and bot response
    # Implementation would analyze message timestamps
    30 # seconds, placeholder
  end

  def calculate_satisfaction_rating
    # Calculate based on user feedback
    4.2 # out of 5, placeholder
  end

  def determine_detail_preference
    # Analyze message lengths and user engagement
    true # placeholder
  end

  def determine_action_preference
    # Analyze click-through rates on suggested actions
    true # placeholder
  end

  def determine_time_preference
    # Analyze when user typically engages
    "evening" # placeholder
  end

  def get_recent_searches
    # Get user's recent property searches
    [] # placeholder
  end

  def get_preferred_property_types
    # Analyze user's search and application history
    [ "apartment", "condo" ] # placeholder
  end

  def get_budget_range
    # Analyze from applications and searches
    { min: 1500, max: 2500 } # placeholder
  end

  def get_location_preferences
    # Extract from search history
    [ "Downtown", "Midtown" ] # placeholder
  end

  def get_user_recent_activity
    {
      recent_searches: get_recent_searches,
      recent_applications: current_user.tenant_rental_applications.limit(3),
      recent_viewings: current_user.property_viewings.limit(3)
    }
  end

  def get_user_preferences
    # Get stored user preferences
    {
      property_types: get_preferred_property_types,
      budget_range: get_budget_range,
      locations: get_location_preferences
    }
  end

  def get_conversation_history
    @conversation&.messages&.order(created_at: :desc)&.limit(10) || []
  end
end
