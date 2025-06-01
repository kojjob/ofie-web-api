# Personality Engine for creating engaging, human-like bot interactions
class Bot::PersonalityEngine
  include ActiveModel::Model

  attr_reader :user, :personality_traits, :communication_style

  def initialize(user:)
    @user = user
    @personality_traits = build_personality_profile
    @communication_style = determine_communication_style
  end

  def personalize_response(response, intent)
    # Apply personality layers to the response
    response = add_personality_markers(response, intent)
    response = adjust_tone(response, intent)
    response = add_contextual_elements(response, intent)
    response = add_emotional_intelligence(response, intent)

    response
  end

  def get_greeting
    time_context = determine_time_context
    user_context = determine_user_context

    greetings = build_contextual_greetings(time_context, user_context)

    greeting = greetings.sample
    personalize_greeting(greeting)
  end

  def get_farewell
    farewells = [
      "Have a wonderful day! 🌟",
      "Feel free to reach out anytime you need help! 💪",
      "Happy house hunting! 🏠✨",
      "Hope I could help make your rental journey easier! 🚀",
      "Take care, and don't hesitate to ask if you need anything else! 💫"
    ]

    farewell = farewells.sample
    add_personal_touch(farewell)
  end

  def get_encouragement_phrase
    encouragements = [
      "You've got this! 💪",
      "I'm here to help every step of the way! 🤝",
      "Great question! Let me help you figure this out. 🧠",
      "No worries, I'll walk you through it! 🚶‍♀️",
      "That's a smart approach! 👏"
    ]

    encouragements.sample
  end

  def get_empathy_phrase(context = nil)
    empathy_phrases = {
      frustrated: [
        "I understand how frustrating this can be 😔",
        "I can see why you'd be concerned about this 💭",
        "This is definitely a challenging situation 🤔"
      ],
      confused: [
        "No worries, this can be confusing! Let me clarify 💡",
        "I totally get why this might seem overwhelming 🌊",
        "These things can be tricky to navigate 🗺️"
      ],
      excited: [
        "I love your enthusiasm! 🎉",
        "How exciting! This is such a big step! ✨",
        "Your excitement is contagious! 😊"
      ],
      anxious: [
        "I understand this feels like a big decision 💭",
        "It's natural to feel nervous about this 🤗",
        "Take a deep breath - we'll figure this out together 🧘‍♀️"
      ]
    }

    if context && empathy_phrases[context]
      empathy_phrases[context].sample
    else
      empathy_phrases.values.flatten.sample
    end
  end

  def should_use_emoji?(intent)
    # Determine when to use emojis based on context
    serious_intents = [ :legal_guidance, :maintenance_intelligent, :financial_planning ]

    return false if serious_intents.include?(intent)
    return false if @communication_style[:formality] == :formal

    true
  end

  def get_conversation_starters
    role_based_starters = if @user.tenant?
      [
        "Looking for your dream home? I can help you search! 🏠",
        "Need help understanding the rental process? I'm here for you! 📋",
        "Want to explore different neighborhoods? Let's dive in! 🗺️",
        "Ready to start your application? I'll guide you through it! ✅"
      ]
    else # landlord
      [
        "Need help managing your properties? I'm here to assist! 🏢",
        "Want to optimize your listings? Let's make them shine! ✨",
        "Questions about tenant applications? I can help you review! 📊",
        "Looking for maintenance management tips? I've got you covered! 🔧"
      ]
    end

    role_based_starters.sample
  end

  private

  def build_personality_profile
    # Create a consistent personality based on user interaction history
    base_traits = {
      helpfulness: 0.9,
      enthusiasm: 0.8,
      professionalism: 0.8,
      warmth: 0.7,
      humor: 0.6,
      patience: 0.9,
      knowledge_confidence: 0.8
    }

    # Adjust based on user preferences if available
    adjust_traits_for_user(base_traits)
  end

  def determine_communication_style
    # Analyze user's communication style and adapt
    style = {
      formality: determine_formality_level,
      verbosity: determine_verbosity_preference,
      emoji_usage: determine_emoji_preference,
      technical_level: determine_technical_level
    }

    style
  end

  def add_personality_markers(response, intent)
    # Add personality-specific phrases and markers

    # Add enthusiasm for positive intents
    if [ :property_search_advanced, :application_guidance ].include?(intent)
      if @personality_traits[:enthusiasm] > 0.7 && should_use_emoji?(intent)
        response = add_enthusiasm_markers(response)
      end
    end

    # Add professional courtesy for serious topics
    if [ :legal_guidance, :lease_consultation ].include?(intent)
      response = add_professional_markers(response)
    end

    # Add warmth and support for potentially stressful situations
    if [ :maintenance_intelligent, :financial_planning ].include?(intent)
      response = add_supportive_markers(response)
    end

    response
  end

  def adjust_tone(response, intent)
    case @communication_style[:formality]
    when :casual
      response = make_more_casual(response)
    when :professional
      response = make_more_professional(response)
    when :friendly
      response = make_more_friendly(response)
    end

    response
  end

  def add_contextual_elements(response, intent)
    # Add time-appropriate greetings
    time_context = determine_time_context

    if response.start_with?("I") && rand < 0.3
      response = add_time_context_greeting(response, time_context)
    end

    # Add user role-specific language
    response = add_role_specific_language(response, intent)

    response
  end

  def add_emotional_intelligence(response, intent)
    # Detect user emotional state and respond appropriately
    recent_sentiment = analyze_recent_sentiment

    case recent_sentiment
    when :frustrated
      response = "#{get_empathy_phrase(:frustrated)} #{response}"
    when :excited
      response = add_excitement_matching(response)
    when :confused
      response = add_clarification_support(response)
    end

    response
  end

  def determine_time_context
    hour = Time.current.hour

    case hour
    when 5..11
      :morning
    when 12..17
      :afternoon
    when 18..21
      :evening
    else
      :late_night
    end
  end

  def determine_user_context
    {
      is_new_user: @user.created_at > 1.week.ago,
      has_active_searches: user_has_recent_activity?(:search),
      has_pending_applications: user_has_recent_activity?(:application),
      expertise_level: determine_expertise_level
    }
  end

  def build_contextual_greetings(time_context, user_context)
    base_greetings = {
      morning: [
        "Good morning! ☀️",
        "Hope you're having a great morning! 🌅",
        "Morning! Ready to find your perfect place? 🏠"
      ],
      afternoon: [
        "Good afternoon! 🌤️",
        "Hope your day is going well! ✨",
        "Afternoon! What can I help you with today? 😊"
      ],
      evening: [
        "Good evening! 🌆",
        "Evening! Still searching for that perfect place? 🏡",
        "Hope you've had a productive day! 🌟"
      ],
      late_night: [
        "Hey there, night owl! 🦉",
        "Late night property hunting? I like your dedication! 💪",
        "Still up searching? Let's find you something amazing! 🌙"
      ]
    }

    greetings = base_greetings[time_context] || base_greetings[:afternoon]

    # Add context-specific modifications
    if user_context[:is_new_user]
      greetings = greetings.map { |g| "#{g} Welcome to Ofie!" }
    end

    greetings
  end

  def add_enthusiasm_markers(response)
    enthusiasm_markers = [
      "Absolutely!",
      "Perfect!",
      "Great question!",
      "I'd be happy to help!",
      "Fantastic!"
    ]

    if rand < 0.4
      marker = enthusiasm_markers.sample
      response = "#{marker} #{response}"
    end

    response
  end

  def add_professional_markers(response)
    # Add professional language for serious topics
    professional_starters = [
      "Let me provide you with the information you need:",
      "Here's what you should know:",
      "I'll walk you through this step by step:",
      "This is important information:"
    ]

    if response.length > 100 && rand < 0.5
      starter = professional_starters.sample
      response = "#{starter}\n\n#{response}"
    end

    response
  end

  def add_supportive_markers(response)
    supportive_phrases = [
      "Don't worry, I'm here to help!",
      "We'll get this sorted out!",
      "I understand this can be stressful.",
      "Let's tackle this together!"
    ]

    if rand < 0.3
      phrase = supportive_phrases.sample
      response = "#{phrase} #{response}"
    end

    response
  end

  def adjust_traits_for_user(traits)
    # Adjust personality traits based on user behavior and preferences

    # More professional for landlords
    if @user.landlord?
      traits[:professionalism] += 0.1
      traits[:humor] -= 0.1
    end

    # More encouraging for new users
    if @user.created_at > 2.weeks.ago
      traits[:warmth] += 0.1
      traits[:patience] += 0.1
    end

    # Adjust based on user's communication style if we have data
    # This would be enhanced with machine learning over time

    traits
  end

  def determine_formality_level
    if @user.landlord?
      :professional
    elsif @user.created_at > 1.week.ago
      :friendly
    else
      :casual
    end
  end

  def determine_verbosity_preference
    # Would analyze user's message lengths over time
    # For now, default based on role
    @user.landlord? ? :detailed : :balanced
  end

  def determine_emoji_preference
    # Younger users and casual contexts prefer more emojis
    if @user.created_at > 1.month.ago
      :moderate
    else
      :minimal
    end
  end

  def determine_technical_level
    # Analyze user's familiarity with rental terminology
    if @user.landlord?
      :high
    elsif @user.tenant_rental_applications.count > 2
      :medium
    else
      :basic
    end
  end

  def analyze_recent_sentiment
    # Analyze recent messages for emotional context
    # This would integrate with sentiment analysis
    :neutral # Default, would be enhanced with actual sentiment data
  end

  def user_has_recent_activity?(activity_type)
    case activity_type
    when :search
      # Check for recent property searches
      false # Placeholder
    when :application
      @user.tenant? && @user.tenant_rental_applications.where("created_at > ?", 1.week.ago).exists?
    else
      false
    end
  end

  def determine_expertise_level
    if @user.landlord?
      @user.properties.count > 5 ? :expert : :intermediate
    else
      @user.tenant_rental_applications.count > 3 ? :experienced : :beginner
    end
  end

  def make_more_casual(response)
    casual_replacements = {
      "I will" => "I'll",
      "do not" => "don't",
      "cannot" => "can't",
      "should not" => "shouldn't",
      "would not" => "wouldn't"
    }

    casual_replacements.each { |formal, casual| response.gsub!(formal, casual) }
    response
  end

  def make_more_professional(response)
    # Remove casual contractions and slang
    professional_replacements = {
      "I'll" => "I will",
      "don't" => "do not",
      "can't" => "cannot",
      "won't" => "will not",
      "hey" => "hello"
    }

    professional_replacements.each { |casual, professional| response.gsub!(casual, professional) }
    response
  end

  def make_more_friendly(response)
    # Add friendly touches without being too casual
    if !response.match?(/[!?.]$/)
      response += "!"
    end

    response
  end

  def personalize_greeting(greeting)
    if @user.name.present?
      "#{greeting} #{@user.name.split.first}! 👋"
    else
      "#{greeting} 👋"
    end
  end

  def add_personal_touch(message)
    if @user.name.present?
      "#{message} - #{@user.name.split.first}"
    else
      message
    end
  end
end
