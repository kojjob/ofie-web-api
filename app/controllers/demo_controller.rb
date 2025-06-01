# Demo controller to showcase the intelligent bot system
class DemoController < ApplicationController
  skip_before_action :authenticate_request, only: [ :bot, :chat ]

  def bot
    # Render the demo bot page
    render file: Rails.root.join("public", "demo_bot.html"), layout: false
  end

  def chat
    # Create a demo user for testing
    @demo_user = create_demo_user
    @conversation = create_demo_conversation(@demo_user)
    @demo_messages = generate_demo_messages(@conversation)

    render json: {
      user: serialize_user(@demo_user),
      conversation: serialize_conversation(@conversation),
      messages: @demo_messages.map { |msg| serialize_message(msg) },
      bot_capabilities: get_bot_capabilities
    }
  end

  private

  def create_demo_user
    # Create or find demo user
    User.find_or_create_by(email: "demo@ofie.com") do |user|
      user.name = "Demo User"
      user.role = "tenant"
      user.password = "demo123"
      user.email_verified = true
      user.preferences = {
        preferred_property_types: [ "apartment", "condo" ],
        budget_max: 2500,
        preferred_locations: [ "Seattle", "Bellevue" ],
        preferred_amenities: [ "parking", "pets", "laundry" ]
      }
    end
  end

  def create_demo_conversation(user)
    bot = Bot.primary_bot

    Conversation.find_or_create_by(
      tenant: user,
      landlord: bot,
      property: nil
    ) do |conversation|
      conversation.subject = "Demo Conversation"
      conversation.status = "active"
      conversation.last_message_at = Time.current
    end
  end

  def generate_demo_messages(conversation)
    bot = Bot.primary_bot
    user = conversation.tenant

    messages = []

    # Bot welcome message
    messages << Message.create!(
      conversation: conversation,
      sender: bot,
      content: "👋 Hi there! I'm your AI rental assistant. I can help you find properties, understand the application process, and answer any questions about rentals!",
      message_type: "text",
      metadata: {
        intent: "greeting",
        confidence: 0.95,
        type: "welcome_message"
      }
    )

    # User message
    messages << Message.create!(
      conversation: conversation,
      sender: user,
      content: "Hi! I'm looking for a 2-bedroom apartment in Seattle under $2500. Can you help?",
      message_type: "text"
    )

    # Bot response with recommendations
    messages << Message.create!(
      conversation: conversation,
      sender: bot,
      content: "🏠 Absolutely! I'd be happy to help you find a 2-bedroom apartment in Seattle under $2500.\n\nBased on your criteria, I understand you're looking for:\n• 🛏️ 2 bedrooms\n• 📍 Location: Seattle\n• 💰 Budget: Under $2500/month\n\nLet me search for properties that match your needs!",
      message_type: "text",
      metadata: {
        intent: "property_search_advanced",
        confidence: 0.92,
        entities: {
          bedroom_count: 2,
          location: "Seattle",
          budget: 2500
        },
        smart_actions: [
          { type: "quick_search", label: "View Results", icon: "🔍" },
          { type: "save_search", label: "Save Search", icon: "💾" },
          { type: "get_alerts", label: "Set Alerts", icon: "🔔" }
        ]
      }
    )

    # User follow-up
    messages << Message.create!(
      conversation: conversation,
      sender: user,
      content: "That sounds great! Do any of them allow pets?",
      message_type: "text"
    )

    # Bot response about pet-friendly options
    messages << Message.create!(
      conversation: conversation,
      sender: bot,
      content: "🐕 Great question! Yes, many of the properties I found are pet-friendly. Here are some excellent pet-friendly options:\n\n**1. Capitol Hill Garden Apartment**\n📍 Seattle, Capitol Hill\n💰 $2,200/month • 🛏️ 2 bed • 🚿 2 bath\n✨ Pet-friendly, Garden access, Parking\n\n**2. Belltown Modern Loft**\n📍 Seattle, Belltown\n💰 $2,450/month • 🛏️ 2 bed • 🚿 1.5 bath\n✨ Pet-friendly, Modern kitchen, City views\n\nWould you like to see more details about any of these properties or schedule a viewing?",
      message_type: "text",
      metadata: {
        intent: "property_details",
        confidence: 0.88,
        entities: {
          amenities: [ "pets" ]
        }
      }
    )

    messages
  end

  def serialize_user(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      preferences: user.preferences
    }
  end

  def serialize_conversation(conversation)
    {
      id: conversation.id,
      subject: conversation.subject,
      status: conversation.status,
      created_at: conversation.created_at,
      last_message_at: conversation.last_message_at
    }
  end

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      sender_role: message.sender.role,
      message_type: message.message_type,
      metadata: message.metadata,
      created_at: message.created_at,
      read: message.read?
    }
  end

  def get_bot_capabilities
    {
      natural_language_processing: {
        intent_classification: true,
        entity_extraction: true,
        sentiment_analysis: true,
        confidence_scoring: true
      },
      conversation_features: {
        context_awareness: true,
        personality_adaptation: true,
        proactive_suggestions: true,
        smart_actions: true
      },
      domain_expertise: {
        property_search: true,
        application_guidance: true,
        lease_consultation: true,
        maintenance_help: true,
        financial_planning: true,
        neighborhood_insights: true,
        legal_guidance: true,
        market_insights: true
      },
      advanced_features: {
        real_time_communication: true,
        property_recommendations: true,
        personalization: true,
        analytics_tracking: true,
        human_handoff: true,
        multi_language_support: false
      }
    }
  end
end
