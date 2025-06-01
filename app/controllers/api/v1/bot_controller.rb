# Streamlined Bot controller for handling bot interactions
require "ostruct"

class Api::V1::BotController < ApplicationController
  # Allow bot chat for both authenticated and non-authenticated users
  skip_before_action :authenticate_request, only: [ :chat, :suggestions, :faqs ]
  skip_before_action :verify_authenticity_token, only: [ :chat, :suggestions, :faqs ]
  before_action :set_bot

  # POST /api/bot/chat
  def chat
    Rails.logger.info "Bot chat request received: #{params.inspect}"

    query = params[:query]
    conversation_id = params[:conversation_id]

    if query.blank?
      Rails.logger.warn "Bot chat: Query is blank"
      return render json: { error: "Query cannot be blank" }, status: :bad_request
    end

    Rails.logger.info "Bot chat: Processing query '#{query}' for user: #{current_user&.id || 'guest'}"

    # For non-authenticated users, provide simple responses
    if current_user.nil?
      Rails.logger.info "Bot chat: Handling guest query"
      response = handle_guest_query(query)
      return render json: {
        conversation_id: nil,
        message: {
          id: SecureRandom.uuid,
          content: response,
          sender: {
            id: "bot",
            name: "Ofie Assistant",
            role: "bot"
          },
          created_at: Time.current
        },
        intent: "guest_help",
        quick_actions: guest_quick_actions,
        confidence: 0.8
      }
    end

    # For authenticated users, use full conversation system
    conversation = find_or_create_conversation(conversation_id)

    # Process the query with BotService
    bot_response = BotService.new(
      user: current_user,
      query: query,
      conversation: conversation
    ).process_query

    # Create the bot's response message
    message = create_bot_message(conversation, bot_response[:response])

    render json: {
      conversation_id: conversation.id,
      message: {
        id: message.id,
        content: message.content,
        sender: {
          id: @bot.id,
          name: @bot.name,
          role: @bot.role
        },
        created_at: message.created_at
      },
      intent: bot_response[:intent],
      quick_actions: bot_response[:quick_actions],
      confidence: bot_response[:confidence]
    }
  rescue => e
    Rails.logger.error "Bot chat error: #{e.message}"
    Rails.logger.error "Bot chat error backtrace: #{e.backtrace.join("\n")}"
    render json: {
      error: "Something went wrong. Please try again.",
      message: {
        id: SecureRandom.uuid,
        content: "I'm experiencing some technical difficulties. Please try again in a moment.",
        sender: {
          id: "bot",
          name: "Ofie Assistant",
          role: "bot"
        },
        created_at: Time.current
      }
    }, status: 200  # Return 200 so the frontend can display the error message
  end

  # POST /api/bot/start_conversation
  def start_conversation
    property_id = params[:property_id]
    initial_message = params[:message]

    property = Property.find(property_id) if property_id.present?

    # Create conversation between user and bot
    conversation = create_bot_conversation(property, initial_message)

    if conversation
      render json: {
        conversation_id: conversation.id,
        message: "Conversation started with Ofie Assistant",
        redirect_url: conversation_path(conversation)
      }
    else
      render json: { error: "Failed to start conversation" }, status: :unprocessable_entity
    end
  end

  # GET /api/bot/suggestions
  def suggestions
    if current_user.nil?
      suggestions = [
        "How does Ofie work?",
        "What services do you offer?",
        "How do I get started?",
        "Browse properties",
        "Contact support"
      ]
    else
      user_type = current_user.role

      suggestions = case user_type
      when "tenant"
        [
          "Find 2-bedroom apartments under $2000",
          "How do I apply for a rental?",
          "What documents do I need?",
          "How do I schedule a viewing?",
          "How do I submit a maintenance request?",
          "How do I pay my rent online?"
        ]
      when "landlord"
        [
          "How do I list a new property?",
          "How do I review rental applications?",
          "How do I manage maintenance requests?",
          "How do I track rental payments?",
          "What are the platform fees?",
          "How do I communicate with tenants?"
        ]
      else
        [
          "How does the platform work?",
          "What services do you offer?",
          "How do I get started?",
          "Contact support"
        ]
      end
    end

    render json: { suggestions: suggestions }
  end

  # GET /api/bot/faqs
  def faqs
    if current_user.nil?
      # Basic FAQs for non-authenticated users
      render json: {
        faqs: {
          "How does Ofie work?" => "Ofie is a comprehensive rental platform that connects renters with landlords. Browse properties, apply online, and manage your rental journey all in one place.",
          "Is Ofie free to use?" => "Yes! Ofie is completely free for renters. You can browse properties, apply for rentals, and use all our features at no cost.",
          "How do I get started?" => "Simply create a free account to start browsing properties, saving favorites, and applying for rentals.",
          "What makes Ofie different?" => "We offer verified listings, streamlined applications, direct landlord communication, and comprehensive rental management tools.",
          "Do I need an account to browse?" => "You can browse properties without an account, but you'll need to sign up to apply for rentals and access advanced features."
        },
        tips: [
          "Create a complete profile to stand out to landlords",
          "Upload all required documents in advance",
          "Set up property alerts for your preferred areas",
          "Read property descriptions and reviews carefully"
        ]
      }
    else
      render json: {
        faqs: KnowledgeBase.faqs,
        tips: current_user.tenant? ? KnowledgeBase.tenant_tips : KnowledgeBase.landlord_tips
      }
    end
  end

  # POST /api/bot/feedback
  def feedback
    message_id = params[:message_id]
    rating = params[:rating] # 1-5 or thumbs up/down
    comment = params[:comment]

    # Log feedback for bot improvement
    Rails.logger.info "Bot feedback - Message: #{message_id}, Rating: #{rating}, Comment: #{comment}"

    # Here you could store feedback in a database table for analysis

    render json: { message: "Thank you for your feedback!" }
  end

  private

  def set_bot
    # Always create a virtual bot for responses since we support guest users
    @bot = OpenStruct.new(
      id: "ofie-assistant",
      name: "Ofie Assistant",
      role: "bot"
    )

    # Try to get the primary bot if it exists and user is authenticated
    if current_user.present?
      begin
        primary_bot = Bot.primary_bot
        @bot = primary_bot if primary_bot
      rescue => e
        Rails.logger.warn "Could not load primary bot: #{e.message}"
        # Keep using the virtual bot
      end
    end
  end

  # Override current_user to handle cases where authentication is skipped
  def current_user
    @current_user ||= find_current_user_safely
  end

  def find_current_user_safely
    return nil unless request.headers["Authorization"].present?

    begin
      super
    rescue => e
      Rails.logger.debug "Authentication failed for bot request: #{e.message}"
      nil
    end
  end

  def find_or_create_conversation(conversation_id)
    if conversation_id.present?
      conversation = Conversation.find_by(id: conversation_id)
      return conversation if conversation && conversation_participant?(conversation)
    end

    # Create new conversation with bot
    create_bot_conversation
  end

  def create_bot_conversation(property = nil, initial_message = nil)
    # Determine conversation participants
    if current_user.tenant?
      landlord = @bot
      tenant = current_user
    else
      landlord = current_user
      tenant = @bot
    end

    # Use a default property if none specified
    property ||= Property.active.first

    conversation = Conversation.create!(
      landlord: landlord,
      tenant: tenant,
      property: property,
      subject: "Chat with Ofie Assistant",
      status: "active"
    )

    # Create initial bot greeting if no initial message
    if initial_message.blank?
      bot_response = BotService.new(
        user: current_user,
        query: "",
        conversation: conversation
      ).process_query

      create_bot_message(conversation, bot_response[:response])
    else
      # Create user's initial message first
      Message.create!(
        conversation: conversation,
        sender: current_user,
        content: initial_message,
        message_type: "text"
      )

      # Then create bot response
      bot_response = BotService.new(
        user: current_user,
        query: initial_message,
        conversation: conversation
      ).process_query

      create_bot_message(conversation, bot_response[:response])
    end

    conversation
  rescue => e
    Rails.logger.error "Failed to create bot conversation: #{e.message}"
    nil
  end

  def create_bot_message(conversation, content)
    Message.create!(
      conversation: conversation,
      sender: @bot,
      content: content,
      message_type: "text"
    )
  end

  def conversation_participant?(conversation)
    conversation.landlord_id == current_user.id || conversation.tenant_id == current_user.id
  end

  # Handle queries from non-authenticated users
  def handle_guest_query(query)
    query_lower = query.downcase.strip

    # Greeting responses
    return "Hi! Welcome to Ofie! 👋\n\nI'm here to help you find your perfect rental property. You can browse our listings, learn about our services, or create an account to get started.\n\nWhat would you like to know?" if query_lower.match?(/\b(hi|hello|hey|greetings)\b/)

    # Property search related
    return "You can browse our available properties right here on the site! Use our search filters to find properties by location, price range, number of bedrooms, and amenities. Would you like me to guide you to the properties page?" if query_lower.match?(/\b(property|properties|apartment|house|rental|search|find)\b/)

    # How it works
    return "Ofie makes renting simple! Here's how it works:\n\n• Browse verified property listings\n• Apply online with digital documents\n• Schedule virtual or in-person viewings\n• Communicate directly with landlords\n• Manage payments and maintenance requests\n\nWant to get started? Create a free account!" if query_lower.match?(/\b(how.*work|what.*do|services|platform)\b/)

    # Application process
    return "Our rental application process is streamlined:\n\n1. Find a property you love\n2. Submit your application online\n3. Upload required documents\n4. Wait for landlord approval\n5. Sign your lease digitally\n\nTo apply for properties, you'll need to create an account first. Would you like me to help you get started?" if query_lower.match?(/\b(apply|application|documents|requirements)\b/)

    # Pricing/costs
    return "Ofie is free for renters! You can browse properties, apply for rentals, and use our platform features at no cost. Landlords pay a small fee to list their properties.\n\nReady to start your search?" if query_lower.match?(/\b(cost|price|fee|free|money|pay)\b/)

    # Account/signup
    return "Creating an account is quick and easy! With an account you can:\n\n• Save favorite properties\n• Submit rental applications\n• Message landlords directly\n• Track application status\n• Manage your rental journey\n\nClick the 'Sign Up' button to get started!" if query_lower.match?(/\b(account|sign.*up|register|join|create)\b/)

    # Contact/support
    return "I'm here to help! For additional support, you can:\n\n• Use this chat for quick questions\n• Visit our Help Center\n• Contact our support team\n• Email us directly\n\nWhat specific question can I help you with?" if query_lower.match?(/\b(help|support|contact|question)\b/)

    # Default response
    "I'd be happy to help you with information about Ofie! I can tell you about:\n\n• How our platform works\n• Browsing and searching properties\n• The rental application process\n• Creating an account\n• Getting support\n\nWhat would you like to know more about?"
  end

  # Quick actions for guest users
  def guest_quick_actions
    [
      { text: "Browse Properties", action: "browse_properties" },
      { text: "How It Works", action: "how_it_works" },
      { text: "Sign Up", action: "sign_up" },
      { text: "Contact Support", action: "contact_support" }
    ]
  end
end
