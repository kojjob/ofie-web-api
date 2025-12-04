# Utility service for managing bot conversations and interactions
class Bot::ConversationManagerService
  include ActiveModel::Model

  attr_reader :user, :bot_user

  def initialize(user)
    @user = user
    @bot_user = Bot.primary_bot
  end

  def find_or_create_conversation(property: nil, subject: nil)
    # Look for existing conversation
    existing_conversation = find_existing_conversation(property)
    return existing_conversation if existing_conversation

    # Create new conversation
    create_new_conversation(property: property, subject: subject)
  end

  def send_welcome_message(conversation)
    personality = Bot::PersonalityEngine.new(user: @user)
    welcome_message = personality.get_greeting

    Message.create!(
      conversation: conversation,
      sender: @bot_user,
      content: welcome_message,
      message_type: "text",
      metadata: {
        type: "welcome_message",
        generated_at: Time.current
      }
    )
  end

  def send_proactive_suggestion(conversation, suggestion_type)
    bot_engine = Bot::IntelligentBotEngine.new(
      user: @user,
      conversation: conversation
    )

    suggestions = bot_engine.generate_proactive_suggestions
    return if suggestions.empty?

    suggestion_message = format_suggestion_message(suggestions, suggestion_type)

    Message.create!(
      conversation: conversation,
      sender: @bot_user,
      content: suggestion_message,
      message_type: "text",
      metadata: {
        type: "proactive_suggestion",
        suggestion_type: suggestion_type,
        suggestions: suggestions,
        generated_at: Time.current
      }
    )
  end

  def cleanup_old_conversations
    # Archive conversations older than 30 days with no activity
    old_conversations = Conversation.where(landlord: @bot_user)
                                   .where("last_message_at < ?", 30.days.ago)
                                   .where.not(status: "archived")

    old_conversations.update_all(status: "archived")

    # Delete very old conversations (6+ months)
    very_old_conversations = Conversation.where(landlord: @bot_user)
                                        .where("last_message_at < ?", 6.months.ago)

    very_old_conversations.destroy_all
  end

  def export_conversation_history(conversation, format = "json")
    case format.to_s
    when "json"
      export_as_json(conversation)
    when "csv"
      export_as_csv(conversation)
    when "txt"
      export_as_text(conversation)
    else
      raise ArgumentError, "Unsupported format: #{format}"
    end
  end

  def analyze_conversation_sentiment(conversation)
    messages = conversation.messages.order(:created_at)
    nlp = Bot::NaturalLanguageProcessor.new

    sentiment_analysis = messages.map do |message|
      sentiment = nlp.analyze_sentiment(message.content)
      {
        message_id: message.id,
        sender_type: message.sender.role,
        sentiment: sentiment[:sentiment],
        confidence: sentiment[:confidence],
        created_at: message.created_at
      }
    end

    {
      overall_sentiment: calculate_overall_sentiment(sentiment_analysis),
      sentiment_progression: sentiment_analysis,
      user_satisfaction_trend: calculate_satisfaction_trend(sentiment_analysis)
    }
  end

  def get_conversation_insights(conversation)
    messages = conversation.messages.includes(:sender).order(:created_at)

    {
      total_messages: messages.count,
      user_messages: messages.where.not(sender: @bot_user).count,
      bot_messages: messages.where(sender: @bot_user).count,
      conversation_duration: calculate_conversation_duration(messages),
      response_times: calculate_response_times(messages),
      intents_covered: extract_covered_intents(messages),
      user_engagement_score: calculate_engagement_score(messages),
      resolution_status: determine_resolution_status(conversation)
    }
  end

  def suggest_human_handoff?(conversation)
    insights = get_conversation_insights(conversation)

    # Suggest handoff if:
    # 1. User seems frustrated (negative sentiment)
    # 2. Bot confidence is consistently low
    # 3. Conversation is going in circles
    # 4. Complex query that requires human expertise

    handoff_indicators = []

    # Check recent bot message confidence
    recent_bot_messages = conversation.messages
                                     .where(sender: @bot_user)
                                     .where("created_at > ?", 10.minutes.ago)
                                     .limit(3)

    low_confidence_count = recent_bot_messages.count do |message|
      message.metadata&.dig("confidence").to_f < 0.5
    end

    handoff_indicators << "low_bot_confidence" if low_confidence_count >= 2

    # Check sentiment
    sentiment_analysis = analyze_conversation_sentiment(conversation)
    if sentiment_analysis[:overall_sentiment] == :negative
      handoff_indicators << "negative_user_sentiment"
    end

    # Check for repetitive patterns
    if detect_repetitive_conversation?(conversation)
      handoff_indicators << "repetitive_conversation"
    end

    # Check for complex queries
    if contains_complex_queries?(conversation)
      handoff_indicators << "complex_queries"
    end

    {
      should_handoff: handoff_indicators.any?,
      reasons: handoff_indicators,
      confidence: calculate_handoff_confidence(handoff_indicators)
    }
  end

  private

  def find_existing_conversation(property)
    query = Conversation.where(
      tenant: @user,
      landlord: @bot_user,
      status: "active"
    )

    if property
      query.where(property: property).first
    else
      query.where(property: nil).first
    end
  end

  def create_new_conversation(property: nil, subject: nil)
    default_subject = if property
      "Questions about #{property.title}"
    else
      "General Assistance"
    end

    conversation = Conversation.create!(
      tenant: @user,
      landlord: @bot_user,
      property: property,
      subject: subject || default_subject,
      status: "active",
      last_message_at: Time.current
    )

    # Send welcome message
    send_welcome_message(conversation)

    conversation
  end

  def format_suggestion_message(suggestions, suggestion_type)
    case suggestion_type
    when "property_search"
      "🏠 I noticed you might be looking for properties. Here are some suggestions:\n\n" +
      suggestions.map { |s| "• #{s}" }.join("\n")
    when "application_help"
      "📋 Need help with your applications? Here's what I can assist with:\n\n" +
      suggestions.map { |s| "• #{s}" }.join("\n")
    when "general"
      "💡 Here are some things I can help you with:\n\n" +
      suggestions.map { |s| "• #{s}" }.join("\n")
    else
      suggestions.join("\n")
    end
  end

  def export_as_json(conversation)
    {
      conversation_id: conversation.id,
      participants: [
        { id: conversation.tenant.id, name: conversation.tenant.name, role: "tenant" },
        { id: conversation.landlord.id, name: conversation.landlord.name, role: "bot" }
      ],
      property: conversation.property ? {
        id: conversation.property.id,
        title: conversation.property.title,
        address: conversation.property.address
      } : nil,
      messages: conversation.messages.order(:created_at).map do |message|
        {
          id: message.id,
          sender: {
            id: message.sender.id,
            name: message.sender.name,
            role: message.sender.role
          },
          content: message.content,
          message_type: message.message_type,
          metadata: message.metadata,
          created_at: message.created_at,
          read: message.read?
        }
      end,
      created_at: conversation.created_at,
      last_message_at: conversation.last_message_at
    }.to_json
  end

  def export_as_csv(conversation)
    require "csv"

    CSV.generate(headers: true) do |csv|
      csv << [ "Timestamp", "Sender", "Role", "Message", "Message Type" ]

      conversation.messages.order(:created_at).each do |message|
        csv << [
          message.created_at.iso8601,
          message.sender.name,
          message.sender.role,
          message.content,
          message.message_type
        ]
      end
    end
  end

  def export_as_text(conversation)
    output = []
    output << "Conversation Export"
    output << "==================="
    output << "Participants: #{conversation.tenant.name} (tenant) and #{conversation.landlord.name} (bot)"
    output << "Property: #{conversation.property&.title || 'General conversation'}"
    output << "Created: #{conversation.created_at}"
    output << ""

    conversation.messages.order(:created_at).each do |message|
      timestamp = message.created_at.strftime("%Y-%m-%d %H:%M:%S")
      sender = "#{message.sender.name} (#{message.sender.role})"
      output << "[#{timestamp}] #{sender}:"
      output << message.content
      output << ""
    end

    output.join("\n")
  end

  def calculate_overall_sentiment(sentiment_analysis)
    return :neutral if sentiment_analysis.empty?

    user_sentiments = sentiment_analysis.select { |s| s[:sender_type] == "tenant" }
    return :neutral if user_sentiments.empty?

    positive_count = user_sentiments.count { |s| s[:sentiment] == :positive }
    negative_count = user_sentiments.count { |s| s[:sentiment] == :negative }

    if positive_count > negative_count
      :positive
    elsif negative_count > positive_count
      :negative
    else
      :neutral
    end
  end

  def calculate_satisfaction_trend(sentiment_analysis)
    user_sentiments = sentiment_analysis.select { |s| s[:sender_type] == "tenant" }
                                       .sort_by { |s| s[:created_at] }

    return [] if user_sentiments.length < 2

    # Calculate trend over time
    trend_points = user_sentiments.each_with_index.map do |sentiment, index|
      score = case sentiment[:sentiment]
      when :positive then 1
      when :negative then -1
      else 0
      end

      {
        timestamp: sentiment[:created_at],
        score: score,
        confidence: sentiment[:confidence]
      }
    end

    trend_points
  end

  def calculate_conversation_duration(messages)
    return 0 if messages.empty?

    first_message = messages.first
    last_message = messages.last

    last_message.created_at - first_message.created_at
  end

  def calculate_response_times(messages)
    response_times = []

    messages.each_cons(2) do |prev_message, current_message|
      if prev_message.sender != current_message.sender
        response_time = current_message.created_at - prev_message.created_at
        response_times << {
          from: prev_message.sender.role,
          to: current_message.sender.role,
          response_time: response_time
        }
      end
    end

    response_times
  end

  def extract_covered_intents(messages)
    bot_messages = messages.where(sender: @bot_user)

    intents = bot_messages.filter_map do |message|
      message.metadata&.dig("intent")
    end

    intents.uniq
  end

  def calculate_engagement_score(messages)
    user_messages = messages.where.not(sender: @bot_user)
    return 0 if user_messages.empty?

    # Factors: message frequency, length, variety
    avg_message_length = user_messages.average("LENGTH(content)") || 0
    message_count = user_messages.count
    conversation_duration = calculate_conversation_duration(messages)

    # Normalize and combine factors
    length_score = [ avg_message_length / 50.0, 10 ].min
    frequency_score = conversation_duration > 0 ? [ message_count / (conversation_duration / 1.hour), 10 ].min : 0

    ((length_score + frequency_score) / 2 * 10).round
  end

  def determine_resolution_status(conversation)
    last_messages = conversation.messages.order(created_at: :desc).limit(3)

    # Look for resolution indicators in recent messages
    resolution_keywords = [ "thank you", "thanks", "solved", "resolved", "helpful", "perfect" ]

    recent_user_messages = last_messages.where.not(sender: @bot_user)

    if recent_user_messages.any? { |msg|
      resolution_keywords.any? { |keyword| msg.content.downcase.include?(keyword) }
    }
      :resolved
    elsif conversation.updated_at < 24.hours.ago
      :stale
    else
      :active
    end
  end

  def detect_repetitive_conversation?(conversation)
    recent_messages = conversation.messages
                                 .where("created_at > ?", 30.minutes.ago)
                                 .order(:created_at)

    return false if recent_messages.count < 4

    # Check for repeated patterns in user messages
    user_messages = recent_messages.where.not(sender: @bot_user)
    message_contents = user_messages.pluck(:content).map(&:downcase)

    # Simple repetition detection
    unique_messages = message_contents.uniq
    repetition_ratio = 1.0 - (unique_messages.length.to_f / message_contents.length)

    repetition_ratio > 0.5
  end

  def contains_complex_queries?(conversation)
    complex_indicators = [
      "legal", "lawsuit", "eviction", "discrimination",
      "lawyer", "court", "sue", "illegal", "violation",
      "emergency", "urgent", "immediately", "asap"
    ]

    recent_user_messages = conversation.messages
                                      .where.not(sender: @bot_user)
                                      .where("created_at > ?", 10.minutes.ago)

    recent_user_messages.any? do |message|
      content = message.content.downcase
      complex_indicators.any? { |indicator| content.include?(indicator) }
    end
  end

  def calculate_handoff_confidence(indicators)
    return 0 if indicators.empty?

    weights = {
      "low_bot_confidence" => 0.4,
      "negative_user_sentiment" => 0.3,
      "repetitive_conversation" => 0.2,
      "complex_queries" => 0.5
    }

    weighted_score = indicators.sum { |indicator| weights[indicator] || 0 }
    [ weighted_score, 1.0 ].min
  end
end
