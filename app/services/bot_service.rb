# AI-generated code: Bot service for processing queries and generating responses
class BotService
  attr_reader :user, :query, :conversation, :context

  # Enable LLM-powered responses by default (can be disabled via config or flag)
  USE_LLM = ENV.fetch("BOT_USE_LLM", "true") == "true"

  def initialize(user:, query:, conversation: nil, context: {}, use_llm: USE_LLM)
    @user = user
    @query = query.to_s.strip.downcase
    @conversation = conversation
    @context = context
    @use_llm = use_llm
  end

  def process_query
    # Return greeting hash when query is blank
    if query.blank?
      greeting_text = default_greeting
      return {
        intent: :greeting,
        response: greeting_text,
        quick_actions: suggest_quick_actions(:greeting),
        confidence: 1.0,
        source: :rule_based
      }
    end

    # Try LLM-powered response first if enabled
    if @use_llm && llm_available?
      llm_result = try_llm_response
      return format_llm_response(llm_result) if llm_result[:success]
    end

    # Fall back to rule-based response
    intent = classify_intent
    response = generate_response(intent)

    {
      intent: intent,
      response: response,
      quick_actions: suggest_quick_actions(intent),
      confidence: calculate_confidence(intent),
      source: :rule_based
    }
  end

  private

  def classify_intent
    # Property search intents
    return :property_search if matches_keywords?([ "find", "search", "looking for", "apartment", "house", "property", "bedroom", "bathroom", "rent" ])
    return :property_details if matches_keywords?([ "details", "information", "about this", "tell me about", "amenities", "features" ])
    return :property_availability if matches_keywords?([ "available", "vacancy", "when can", "move in", "lease start" ])

    # Application and rental process
    return :application_help if matches_keywords?([ "apply", "application", "how to apply", "rental application", "documents needed" ])
    return :application_status if matches_keywords?([ "application status", "my application", "application update", "approved", "rejected" ])
    return :lease_questions if matches_keywords?([ "lease", "contract", "agreement", "terms", "signing" ])

    # Viewing and scheduling
    return :viewing_request if matches_keywords?([ "viewing", "tour", "see the property", "visit", "schedule", "appointment" ])
    return :viewing_status if matches_keywords?([ "my viewing", "viewing status", "appointment status" ])

    # Maintenance requests
    return :maintenance_help if matches_keywords?([ "maintenance", "repair", "broken", "not working", "fix", "problem with" ])
    return :maintenance_emergency if matches_keywords?([ "emergency", "urgent", "no heat", "no water", "flooding", "gas leak" ])
    return :maintenance_status if matches_keywords?([ "maintenance status", "repair status", "my request" ])

    # Payments
    return :payment_help if matches_keywords?([ "payment", "pay rent", "how to pay", "payment methods" ])
    return :payment_status if matches_keywords?([ "payment status", "my payments", "payment history", "late fee" ])

    # Platform navigation
    return :platform_help if matches_keywords?([ "how to use", "navigate", "features", "help with platform" ])
    return :account_help if matches_keywords?([ "account", "profile", "settings", "password", "login" ])

    # General inquiries
    return :contact_info if matches_keywords?([ "contact", "phone", "email", "support", "human", "speak to someone" ])
    return :general_info if matches_keywords?([ "what is", "explain", "tell me about", "information" ])

    # Default
    :unknown
  end

  def generate_response(intent)
    case intent
    when :property_search
      handle_property_search
    when :property_details
      handle_property_details
    when :property_availability
      handle_property_availability
    when :application_help
      handle_application_help
    when :application_status
      handle_application_status
    when :lease_questions
      handle_lease_questions
    when :viewing_request
      handle_viewing_request
    when :viewing_status
      handle_viewing_status
    when :maintenance_help
      handle_maintenance_help
    when :maintenance_emergency
      handle_maintenance_emergency
    when :maintenance_status
      handle_maintenance_status
    when :payment_help
      handle_payment_help
    when :payment_status
      handle_payment_status
    when :platform_help
      handle_platform_help
    when :account_help
      handle_account_help
    when :contact_info
      handle_contact_info
    when :general_info
      handle_general_info
    else
      handle_unknown_query
    end
  end

  def handle_property_search
    # Extract search criteria from query
    bedrooms = extract_number_before([ "bedroom", "bed", "br" ])
    bathrooms = extract_number_before([ "bathroom", "bath", "ba" ])
    max_price = extract_price
    property_type = extract_property_type

    response = "I'd be happy to help you find the perfect property! "

    if bedrooms || bathrooms || max_price || property_type
      response += "Based on your message, I understand you're looking for:"
      response += "\n• #{bedrooms} bedroom(s)" if bedrooms
      response += "\n• #{bathrooms} bathroom(s)" if bathrooms
      response += "\n• Maximum rent: $#{max_price}" if max_price
      response += "\n• Property type: #{property_type}" if property_type
      response += "\n\nLet me search for properties matching your criteria."
    else
      response += "To help you find the best properties, could you tell me:\n"
      response += "• How many bedrooms do you need?\n"
      response += "• What's your budget range?\n"
      response += "• Any specific location preferences?\n"
      response += "• Do you need any specific amenities?"
    end

    response
  end

  def handle_property_details
    if conversation&.property
      property = conversation.property
      response = "Here are the details for #{property.title}:\n\n"
      response += "📍 Location: #{property.address}, #{property.city}\n"
      response += "💰 Rent: $#{property.price}/month\n"
      response += "🛏️ Bedrooms: #{property.bedrooms}\n"
      response += "🚿 Bathrooms: #{property.bathrooms}\n"
      response += "📐 Size: #{property.square_feet} sq ft\n" if property.square_feet
      response += "🏠 Type: #{property.property_type.humanize}\n\n"

      if property.amenities_list.any?
        response += "✨ Amenities:\n"
        property.amenities_list.each { |amenity| response += "• #{amenity}\n" }
      end

      response += "\n#{property.description}" if property.description.present?
    else
      response = "I'd be happy to provide property details! Could you specify which property you're interested in, or share a property listing link?"
    end

    response
  end

  def handle_application_help
    response = "I'll guide you through the rental application process!\n\n"
    response += "📋 **Application Process:**\n"
    KnowledgeBase.rental_application_process.each { |step| response += "#{step}\n" }
    response += "\n📄 **Required Documents:**\n"
    KnowledgeBase.required_documents.each { |doc| response += "• #{doc}\n" }
    response += "\n💰 **Income Requirements:**\n#{KnowledgeBase.income_requirements}"
    response
  end

  def handle_maintenance_help
    if matches_keywords?([ "emergency", "urgent" ])
      return handle_maintenance_emergency
    end

    response = "I can help you with maintenance requests! Here's what you need to know:\n\n"
    response += "🔧 **Common Maintenance Categories:**\n"
    KnowledgeBase.maintenance_categories.each do |category, description|
      response += "• **#{category.humanize}**: #{description}\n"
    end

    response += "\n⚠️ **Emergency vs. Routine:**\n"
    response += "**Emergency issues (report immediately):**\n"
    KnowledgeBase.emergency_vs_routine[:emergency].each { |item| response += "• #{item}\n" }
    response += "\n**Routine issues (can wait for normal business hours):**\n"
    KnowledgeBase.emergency_vs_routine[:routine].each { |item| response += "• #{item}\n" }

    response
  end

  def handle_maintenance_emergency
    "🚨 **EMERGENCY MAINTENANCE** 🚨\n\n" +
    "If this is a true emergency (safety hazard, no heat/water, flooding, gas leak), please:\n\n" +
    "1. **Submit an emergency maintenance request immediately**\n" +
    "2. **Contact your landlord directly by phone**\n" +
    "3. **If it's a gas leak or immediate safety hazard, call emergency services (911)**\n\n" +
    "For non-emergency issues, you can submit a regular maintenance request and it will be addressed during business hours."
  end

  def handle_payment_help
    response = "I can help you with rent payments! Here's what you need to know:\n\n"
    response += "💳 **Payment Methods:**\n"
    KnowledgeBase.payment_methods.each { |method| response += "• #{method}\n" }
    response += "\n⏰ **Payment Timing:**\n#{KnowledgeBase.late_payment_info}"
    response
  end

  def handle_platform_help
    response = "I'm here to help you navigate the platform! Here are the main features:\n\n"
    KnowledgeBase.platform_features.each do |feature, description|
      response += "• **#{feature.humanize}**: #{description}\n"
    end
    response += "\nWhat specific feature would you like help with?"
    response
  end

  def handle_contact_info
    "If you need to speak with a human representative, you can:\n\n" +
    "📧 Email: support@ofie.com\n" +
    "📞 Phone: 1-800-OFIE-HELP\n" +
    "💬 Live Chat: Available 9 AM - 6 PM EST\n\n" +
    "For property-specific questions, you can also message the landlord directly through the conversation feature."
  end

  def handle_unknown_query
    responses = [
      "I'm not sure I understand that question. Could you rephrase it or ask about something specific like properties, applications, or maintenance?",
      "I'd love to help! Could you be more specific about what you're looking for? I can assist with property searches, rental applications, maintenance requests, and more.",
      "I'm here to help with your rental needs! Try asking about finding properties, application processes, maintenance requests, or platform features."
    ]
    responses.sample
  end

  def default_greeting
    greeting = user.tenant? ? "Hello! I'm your Ofie assistant. I can help you find properties, apply for rentals, and answer questions about the platform." :
               "Hello! I'm your Ofie assistant. I can help you manage your properties, review applications, and answer platform questions."

    greeting += "\n\nWhat can I help you with today?"
    greeting
  end

  # Helper methods for response generation
  def handle_application_status
    "To check your application status, visit the 'My Applications' section in your dashboard. You'll see the current status of all your submitted applications and any updates from landlords."
  end

  def handle_lease_questions
    "Lease agreements contain important terms like rent amount, lease duration, security deposit, and property rules. Always read carefully before signing and ask questions about anything unclear. Your landlord should explain all terms."
  end

  def handle_viewing_request
    "To schedule a property viewing, click the 'Schedule Viewing' button on any property listing. You can suggest preferred times and the landlord will confirm availability."
  end

  def handle_viewing_status
    "Check your 'My Viewings' section to see all scheduled appointments, confirmations, and any messages from landlords about viewing arrangements."
  end

  def handle_maintenance_status
    "You can track your maintenance requests in the 'Maintenance' section of your dashboard. You'll see the status, any updates from your landlord, and estimated completion times."
  end

  def handle_payment_status
    "View your payment history and upcoming payments in the 'Payments' section. You can see payment confirmations, due dates, and set up automatic payments."
  end

  def handle_account_help
    "For account issues, visit your 'Profile' section to update personal information, change passwords, or manage notification preferences. Contact support if you need additional help."
  end

  def handle_general_info
    "I can provide information about properties, rental processes, platform features, and more. What specific topic would you like to know about?"
  end

  def handle_property_availability
    "To check property availability, look for the 'Available' status on listings. You can also contact the landlord directly to confirm move-in dates and lease start options."
  end

  # Utility methods
  def matches_keywords?(keywords)
    keywords.any? { |keyword| query.include?(keyword) }
  end

  def extract_number_before(words)
    words.each do |word|
      match = query.match(/(\d+)\s*#{word}/)
      return match[1].to_i if match
    end
    nil
  end

  def extract_price
    match = query.match(/\$([\d,]+)/) || query.match(/(\d+)\s*dollars?/)
    match ? match[1].gsub(",", "").to_i : nil
  end

  def extract_property_type
    KnowledgeBase.property_types.keys.find { |type| query.include?(type) }
  end

  def suggest_quick_actions(intent)
    case intent
    when :property_search
      [ "Search Properties", "Set Search Alerts", "View Favorites" ]
    when :application_help
      [ "Start Application", "Upload Documents", "Check Requirements" ]
    when :maintenance_help
      [ "Submit Request", "Emergency Contact", "View History" ]
    when :payment_help
      [ "Make Payment", "Set Auto-Pay", "View History" ]
    when :viewing_request
      [ "Schedule Viewing", "My Viewings", "Contact Landlord" ]
    else
      [ "Browse Properties", "My Dashboard", "Contact Support" ]
    end
  end

  def calculate_confidence(intent)
    intent == :unknown ? 0.3 : 0.8
  end

  # LLM integration helpers
  def llm_available?
    defined?(BotServices::LlmService) &&
      (ENV["ANTHROPIC_API_KEY"].present? ||
       ENV["OPENAI_API_KEY"].present? ||
       ENV["GOOGLE_API_KEY"].present?)
  end

  def try_llm_response
    # Enhance context with classified intent for better LLM prompting
    intent = classify_intent
    enhanced_context = context.merge(
      detected_intent: intent,
      entities: extract_all_entities
    )

    BotServices::LlmService.new(
      user: user,
      query: query,
      conversation: conversation,
      context: enhanced_context
    ).generate_response
  rescue => e
    Rails.logger.error "[BotService] LLM integration error: #{e.message}"
    { success: false, error: e.message }
  end

  def format_llm_response(llm_result)
    # Classify intent for quick actions even with LLM response
    intent = classify_intent

    {
      intent: intent,
      response: llm_result[:response],
      quick_actions: suggest_quick_actions(intent),
      confidence: 0.9, # Higher confidence for LLM responses
      source: llm_result[:source],
      cached: llm_result[:cached] || false
    }
  end

  def extract_all_entities
    {
      bedrooms: extract_number_before([ "bedroom", "bed", "br" ]),
      bathrooms: extract_number_before([ "bathroom", "bath", "ba" ]),
      max_price: extract_price,
      property_type: extract_property_type
    }.compact
  end
end
