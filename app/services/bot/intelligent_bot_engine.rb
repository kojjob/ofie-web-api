# Advanced Intelligent Bot Engine with NLP, Context Awareness, and Personalization
class Bot::IntelligentBotEngine
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attr_reader :user, :conversation, :message_history, :context

  def initialize(user:, conversation: nil, context: {})
    @user = user
    @conversation = conversation
    @context = context
    @message_history = load_conversation_history
    @nlp_processor = Bot::NaturalLanguageProcessor.new
    @context_manager = Bot::ContextManager.new(user: user, conversation: conversation)
    @personality = Bot::PersonalityEngine.new(user: user)
  end

  def process_message(message_content)
    # Preprocess and clean the message
    cleaned_message = preprocess_message(message_content)

    # Update conversation context
    @context_manager.update_context(cleaned_message)

    # Advanced intent classification with confidence scoring
    intent_result = @nlp_processor.classify_intent_advanced(cleaned_message, @context_manager.current_context)

    # Entity extraction for structured data
    entities = @nlp_processor.extract_entities(cleaned_message)

    # Generate contextually aware response
    response = generate_intelligent_response(intent_result, entities, cleaned_message)

    # Add personality and human touch
    personalized_response = @personality.personalize_response(response, intent_result[:intent])

    # Generate rich media attachments if applicable
    media_attachments = generate_media_attachments(intent_result[:intent], entities)

    # Suggest smart actions
    smart_actions = generate_smart_actions(intent_result[:intent], entities)

    # Learning: Update bot knowledge based on interaction
    update_learning_data(intent_result, entities, cleaned_message)

    {
      response: personalized_response,
      intent: intent_result[:intent],
      confidence: intent_result[:confidence],
      entities: entities,
      media_attachments: media_attachments,
      smart_actions: smart_actions,
      conversation_suggestions: generate_conversation_suggestions,
      typing_delay: calculate_typing_delay(personalized_response),
      requires_human_handoff: intent_result[:confidence] < 0.3 || intent_result[:intent] == :complex_query
    }
  end

  def generate_proactive_suggestions
    # Analyze user behavior and generate helpful suggestions
    suggestions = []

    # Property search suggestions based on user history
    if user.tenant?
      suggestions.concat(generate_property_suggestions)
      suggestions.concat(generate_application_reminders)
    end

    # Landlord-specific suggestions
    if user.landlord?
      suggestions.concat(generate_landlord_suggestions)
      suggestions.concat(generate_maintenance_suggestions)
    end

    # Platform usage suggestions
    suggestions.concat(generate_platform_suggestions)

    suggestions.take(3) # Limit to top 3 suggestions
  end

  private

  def preprocess_message(message)
    # Clean and normalize the message
    cleaned = message.to_s.strip

    # Remove extra spaces and normalize punctuation
    cleaned = cleaned.gsub(/\s+/, " ")
    cleaned = cleaned.gsub(/[.]{2,}/, "...")

    # Handle common abbreviations and expansions
    cleaned = expand_abbreviations(cleaned)

    cleaned
  end

  def generate_intelligent_response(intent_result, entities, original_message)
    intent = intent_result[:intent]
    confidence = intent_result[:confidence]

    # Use different response strategies based on confidence
    if confidence > 0.8
      generate_confident_response(intent, entities, original_message)
    elsif confidence > 0.5
      generate_moderate_confidence_response(intent, entities, original_message)
    else
      generate_clarification_response(intent_result[:possible_intents], original_message)
    end
  end

  def generate_confident_response(intent, entities, original_message)
    case intent
    when :property_search_advanced
      handle_advanced_property_search(entities)
    when :property_comparison
      handle_property_comparison(entities)
    when :application_guidance
      handle_application_guidance_advanced(entities)
    when :lease_consultation
      handle_lease_consultation(entities)
    when :maintenance_intelligent
      handle_intelligent_maintenance(entities)
    when :financial_planning
      handle_financial_planning(entities)
    when :neighborhood_info
      handle_neighborhood_information(entities)
    when :legal_guidance
      handle_legal_guidance(entities)
    when :market_insights
      handle_market_insights(entities)
    when :personalized_recommendations
      handle_personalized_recommendations(entities)
    else
      Bot::ResponseTemplates.get_template(intent, entities, @context_manager.current_context)
    end
  end

  def handle_advanced_property_search(entities)
    search_criteria = extract_search_criteria(entities)

    # Get personalized property recommendations
    properties = PropertyRecommendationEngine.new(@user).recommend(search_criteria)

    if properties.any?
      response = "🏠 I found #{properties.count} properties that match your preferences!\n\n"

      properties.first(3).each_with_index do |property, index|
        response += format_property_card(property, index + 1)
      end

      if properties.count > 3
        response += "\n💡 I have #{properties.count - 3} more properties that might interest you. Would you like to see them?"
      end

      response += "\n\n✨ **Smart Filters Applied:**\n"
      search_criteria.each { |key, value| response += "• #{key.humanize}: #{value}\n" }

    else
      response = "🔍 I couldn't find properties matching your exact criteria, but I have some great alternatives!\n\n"
      response += suggest_alternative_searches(search_criteria)
    end

    response
  end

  def handle_application_guidance_advanced(entities)
    application_stage = determine_application_stage

    response = "📋 **Rental Application Guidance**\n\n"

    case application_stage
    when :pre_application
      response += generate_pre_application_guidance
    when :in_progress
      response += generate_in_progress_guidance
    when :submitted
      response += generate_post_submission_guidance
    when :approved
      response += generate_lease_preparation_guidance
    end

    # Add personalized tips based on user profile
    response += generate_personalized_application_tips

    response
  end

  def handle_intelligent_maintenance(entities)
    # Analyze maintenance request context
    urgency = determine_maintenance_urgency(entities)
    category = entities[:maintenance_category] || "general"

    response = "🔧 **Maintenance Assistant**\n\n"

    if urgency == :emergency
      response += "🚨 **Emergency Detected!**\n"
      response += Bot::EmergencyProtocols.get_emergency_response(category)
    else
      response += "I'll help you with your maintenance request. "
      response += Bot::MaintenanceGuide.get_category_guidance(category)

      # Add preventive maintenance tips
      response += "\n\n💡 **Prevention Tips:**\n"
      response += Bot::MaintenanceGuide.get_prevention_tips(category)
    end

    # Add smart scheduling if not emergency
    unless urgency == :emergency
      response += "\n\n📅 **Smart Scheduling:**\n"
      response += generate_maintenance_scheduling_options
    end

    response
  end

  def handle_financial_planning(entities)
    budget = entities[:budget]&.to_f
    income = entities[:income]&.to_f

    response = "💰 **Financial Planning Assistant**\n\n"

    if budget && income
      analysis = Bot::FinancialAnalyzer.analyze_affordability(budget, income)
      response += format_financial_analysis(analysis)
    else
      response += "Let me help you plan your rental budget!\n\n"
      response += Bot::FinancialGuide.get_budgeting_guide(@user)
    end

    # Add personalized savings tips
    response += "\n\n💡 **Smart Savings Tips:**\n"
    response += Bot::FinancialGuide.get_savings_tips(@user)

    response
  end

  def handle_neighborhood_information(entities)
    location = entities[:location] || @context_manager.get_context(:last_searched_location)

    response = "🏘️ **Neighborhood Insights**\n\n"

    if location
      neighborhood_data = Bot::NeighborhoodDataService.get_insights(location)
      response += format_neighborhood_insights(neighborhood_data)
    else
      response += "Which neighborhood would you like to learn about? I can provide insights on:\n"
      response += "• Safety and crime statistics\n"
      response += "• Local amenities and services\n"
      response += "• Transportation options\n"
      response += "• Schools and education\n"
      response += "• Cost of living analysis\n"
    end

    response
  end

  def generate_media_attachments(intent, entities)
    attachments = []

    case intent
    when :property_search_advanced
      attachments << create_property_carousel(entities)
    when :market_insights
      attachments << create_market_chart(entities)
    when :neighborhood_info
      attachments << create_neighborhood_map(entities)
    when :financial_planning
      attachments << create_budget_calculator(entities)
    when :maintenance_intelligent
      attachments << create_maintenance_visual_guide(entities)
    end

    attachments.compact
  end

  def generate_smart_actions(intent, entities)
    actions = []

    case intent
    when :property_search_advanced
      actions += [
        { type: "quick_search", label: "Refine Search", icon: "🔍" },
        { type: "save_search", label: "Save Search", icon: "💾" },
        { type: "get_alerts", label: "Set Alerts", icon: "🔔" }
      ]
    when :application_guidance
      actions += [
        { type: "start_application", label: "Start Application", icon: "📝" },
        { type: "upload_documents", label: "Upload Documents", icon: "📄" },
        { type: "check_requirements", label: "Check Requirements", icon: "✅" }
      ]
    when :maintenance_intelligent
      actions += [
        { type: "create_request", label: "Create Request", icon: "🔧" },
        { type: "emergency_contact", label: "Emergency Contact", icon: "🚨" },
        { type: "maintenance_history", label: "View History", icon: "📋" }
      ]
    end

    # Add contextual actions based on user state
    actions += generate_contextual_actions

    actions.uniq
  end

  def generate_conversation_suggestions(intent = nil)
    suggestions = []

    # Intent-specific follow-up questions
    case intent
    when :property_search_advanced
      suggestions += [
        "Show me properties with parking",
        "What about pet-friendly options?",
        "Find properties under $2000"
      ]
    when :application_guidance
      suggestions += [
        "What documents do I need?",
        "How long does approval take?",
        "Can you check my application status?"
      ]
    end

    # General helpful suggestions
    suggestions += [
      "Help me find properties",
      "Explain the rental process",
      "Show my dashboard",
      "Contact support"
    ]

    suggestions.take(4)
  end

  def calculate_typing_delay(response)
    # Simulate human-like typing speed
    base_delay = 1000 # 1 second base
    words = response.split.count
    typing_speed = 150 # words per minute

    calculated_delay = (words.to_f / typing_speed * 60 * 1000).to_i

    # Cap between 1-5 seconds for better UX
    [ calculated_delay, 5000 ].min.clamp(1000, 5000)
  end

  def load_conversation_history
    return [] unless @conversation

    @conversation.messages
                 .order(created_at: :desc)
                 .limit(10)
                 .pluck(:content, :sender_id)
                 .map { |content, sender_id| { content: content, is_bot: sender_id == Bot.primary_bot.id } }
  end

  def update_learning_data(intent_result, entities, message)
    # Store interaction data for bot improvement
    Bot::LearningData.create!(
      user: @user,
      message: message,
      intent: intent_result[:intent],
      confidence: intent_result[:confidence],
      entities: entities,
      context: @context_manager.current_context,
      session_id: @context_manager.session_id
    )
  end

  # Helper methods for specific response generation
  def format_property_card(property, index)
    card = "**#{index}. #{property.title}**\n"
    card += "📍 #{property.address}, #{property.city}\n"
    card += "💰 $#{property.price}/month • 🛏️ #{property.bedrooms} bed • 🚿 #{property.bathrooms} bath\n"
    card += "✨ #{property.amenities_list.first(3).join(', ')}\n"
    card += "⭐ #{property.average_rating}/5 (#{property.reviews_count} reviews)\n\n"
  end

  def expand_abbreviations(text)
    abbreviations = {
      "apt" => "apartment",
      "br" => "bedroom",
      "ba" => "bathroom",
      "sq ft" => "square feet",
      "util" => "utilities",
      "pkg" => "parking",
      "a/c" => "air conditioning",
      "w/d" => "washer dryer",
      "ht" => "heat",
      "hw" => "hot water"
    }

    abbreviations.each { |abbr, full| text.gsub!(/\b#{abbr}\b/i, full) }
    text
  end
end
