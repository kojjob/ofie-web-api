# Advanced Natural Language Processing for the Ofie Bot
class Bot::NaturalLanguageProcessor
  include ActiveModel::Model

  # Advanced intent patterns with confidence scoring
  INTENT_PATTERNS = {
    property_search_advanced: {
      primary: [
        /find|search|looking for|show me.*(?:property|properties|apartment|house|home)/i,
        /(?:i want|need|require).*(?:bedroom|bathroom|parking|pet)/i,
        /budget.*(?:\$|dollar|under|around|between)/i
      ],
      secondary: [
        /area|neighborhood|location|city/i,
        /amenities|features|included/i,
        /price range|rent|cost/i
      ],
      confidence_base: 0.9
    },

    property_comparison: {
      primary: [
        /compare.*(?:property|properties|apartment)/i,
        /(?:vs|versus|difference between)/i,
        /which.*better|pros.*cons/i
      ],
      confidence_base: 0.85
    },

    application_guidance: {
      primary: [
        /apply|application|rental application/i,
        /(?:documents|paperwork).*(?:need|required)/i,
        /income.*requirement|credit.*check/i
      ],
      secondary: [
        /approval|review|status/i,
        /timeline|how long/i
      ],
      confidence_base: 0.9
    },

    lease_consultation: {
      primary: [
        /lease.*(?:agreement|contract|terms)/i,
        /signing|sign.*lease/i,
        /tenant.*rights|landlord.*responsibilities/i
      ],
      confidence_base: 0.85
    },

    maintenance_intelligent: {
      primary: [
        /maintenance|repair|broken|fix|not working/i,
        /emergency|urgent|flooding|no heat|no water/i,
        /plumbing|electrical|hvac|appliance/i
      ],
      secondary: [
        /schedule|appointment/i,
        /cost|estimate/i
      ],
      confidence_base: 0.9
    },

    financial_planning: {
      primary: [
        /budget|afford|financial|money/i,
        /income.*rent|debt.*ratio/i,
        /security deposit|first month/i
      ],
      confidence_base: 0.8
    },

    neighborhood_info: {
      primary: [
        /neighborhood|area.*safe|crime.*rate/i,
        /school|transportation|commute/i,
        /local.*(?:stores|restaurants|amenities)/i
      ],
      confidence_base: 0.85
    },

    legal_guidance: {
      primary: [
        /legal|law|rights|eviction/i,
        /discrimination|fair housing/i,
        /deposit.*return|security.*deposit/i
      ],
      confidence_base: 0.8
    },

    market_insights: {
      primary: [
        /market.*(?:trend|price|rate)/i,
        /rental.*market|property.*value/i,
        /investment|roi|return/i
      ],
      confidence_base: 0.8
    },

    personalized_recommendations: {
      primary: [
        /recommend|suggest|advice/i,
        /what.*should.*(?:i|we)/i,
        /help.*(?:choose|decide|pick)/i
      ],
      confidence_base: 0.7
    }
  }.freeze

  # Entity extraction patterns
  ENTITY_PATTERNS = {
    bedroom_count: /(\d+)[\s-]*(?:bed|bedroom|br)/i,
    bathroom_count: /(\d+)[\s-]*(?:bath|bathroom|ba)/i,
    budget: /\$?([\d,]+)(?:\s*(?:per month|\/month|monthly)?)?/i,
    location: /(?:in|near|around|at)\s+([a-zA-Z\s,]+?)(?:\s|$|[.!?])/i,
    property_type: /(apartment|house|condo|townhouse|studio|loft)/i,
    amenities: /(parking|pet|furnished|utilities|laundry|gym|pool|balcony)/i,
    urgency: /(emergency|urgent|asap|immediately|right now)/i,
    timeline: /(?:within|in|by)\s+(\d+)\s*(day|week|month|year)s?/i,
    square_feet: /(\d+)\s*(?:sq\s*ft|square\s*feet)/i,
    lease_duration: /(\d+)\s*(?:month|year)s?\s*lease/i
  }.freeze

  def classify_intent_advanced(message, context = {})
    message_lower = message.downcase
    intent_scores = {}

    # Calculate scores for each intent
    INTENT_PATTERNS.each do |intent, patterns|
      score = calculate_intent_score(message_lower, patterns, context)
      intent_scores[intent] = score if score > 0.1
    end

    # Get the highest scoring intent
    if intent_scores.any?
      top_intent = intent_scores.max_by { |_, score| score }
      possible_intents = intent_scores.select { |_, score| score > 0.3 }.keys

      {
        intent: top_intent[0],
        confidence: top_intent[1],
        possible_intents: possible_intents,
        all_scores: intent_scores
      }
    else
      {
        intent: :unknown,
        confidence: 0.0,
        possible_intents: [],
        all_scores: {}
      }
    end
  end

  def extract_entities(message)
    entities = {}

    ENTITY_PATTERNS.each do |entity_type, pattern|
      matches = message.scan(pattern).flatten.compact

      case entity_type
      when :bedroom_count, :bathroom_count
        entities[entity_type] = matches.first&.to_i
      when :budget
        entities[entity_type] = clean_price(matches.first)
      when :location
        entities[entity_type] = clean_location(matches.first)
      when :property_type
        entities[entity_type] = matches.first&.downcase
      when :amenities
        entities[entity_type] = matches.map(&:downcase).uniq
      when :urgency
        entities[entity_type] = determine_urgency_level(matches)
      when :timeline
        entities[entity_type] = parse_timeline(matches)
      when :square_feet
        entities[entity_type] = matches.first&.to_i
      when :lease_duration
        entities[entity_type] = matches.first&.to_i
      else
        entities[entity_type] = matches.first
      end
    end

    # Extract compound entities
    entities.merge!(extract_compound_entities(message))

    entities.compact
  end

  def analyze_sentiment(message)
    # Simple sentiment analysis (would integrate with more advanced NLP in production)
    positive_words = %w[great excellent amazing good nice beautiful perfect love like want happy excited]
    negative_words = %w[bad terrible awful horrible hate dislike problems issues broken frustrated angry]

    words = message.downcase.split
    positive_count = words.count { |word| positive_words.include?(word) }
    negative_count = words.count { |word| negative_words.include?(word) }

    if positive_count > negative_count
      { sentiment: :positive, confidence: (positive_count.to_f / words.length) }
    elsif negative_count > positive_count
      { sentiment: :negative, confidence: (negative_count.to_f / words.length) }
    else
      { sentiment: :neutral, confidence: 0.5 }
    end
  end

  def extract_user_preferences(message_history)
    preferences = {
      property_types: [],
      amenities: [],
      locations: [],
      budget_range: nil,
      bedroom_preference: nil,
      bathroom_preference: nil
    }

    message_history.each do |message|
      entities = extract_entities(message[:content])

      preferences[:property_types] << entities[:property_type] if entities[:property_type]
      preferences[:amenities].concat(entities[:amenities] || [])
      preferences[:locations] << entities[:location] if entities[:location]
      preferences[:budget_range] = entities[:budget] if entities[:budget]
      preferences[:bedroom_preference] = entities[:bedroom_count] if entities[:bedroom_count]
      preferences[:bathroom_preference] = entities[:bathroom_count] if entities[:bathroom_count]
    end

    # Clean and deduplicate
    preferences[:property_types].uniq!
    preferences[:amenities].uniq!
    preferences[:locations].uniq!

    preferences
  end

  private

  def calculate_intent_score(message, patterns, context)
    base_confidence = patterns[:confidence_base] || 0.5
    score = 0.0

    # Primary pattern matching
    if patterns[:primary]
      primary_matches = patterns[:primary].count { |pattern| message.match?(pattern) }
      score += (primary_matches.to_f / patterns[:primary].length) * base_confidence
    end

    # Secondary pattern matching (bonus points)
    if patterns[:secondary]
      secondary_matches = patterns[:secondary].count { |pattern| message.match?(pattern) }
      score += (secondary_matches.to_f / patterns[:secondary].length) * 0.2
    end

    # Context boost
    score += calculate_context_boost(message, patterns, context)

    # Length penalty for very short messages
    score *= 0.8 if message.split.length < 3

    [ score, 1.0 ].min
  end

  def calculate_context_boost(message, patterns, context)
    boost = 0.0

    # Recent conversation context
    if context[:recent_intent] && patterns[:follows_from]&.include?(context[:recent_intent])
      boost += 0.2
    end

    # User role context
    if context[:user_role] == "tenant" && patterns[:tenant_focused]
      boost += 0.1
    elsif context[:user_role] == "landlord" && patterns[:landlord_focused]
      boost += 0.1
    end

    # Time-based context
    if patterns[:time_sensitive] && context[:urgency_detected]
      boost += 0.15
    end

    boost
  end

  def extract_compound_entities(message)
    entities = {}

    # Price range extraction
    price_range_match = message.match(/between\s+\$?([\d,]+)\s+(?:and|to)\s+\$?([\d,]+)/i)
    if price_range_match
      entities[:price_range] = {
        min: clean_price(price_range_match[1]),
        max: clean_price(price_range_match[2])
      }
    end

    # Date/time extraction
    date_match = message.match(/(?:on|by|before|after)\s+(\w+\s+\d+(?:st|nd|rd|th)?(?:,?\s+\d{4})?)/i)
    entities[:date] = parse_date(date_match[1]) if date_match

    # Property size range
    size_range_match = message.match(/(\d+)\s*(?:to|-)\s*(\d+)\s*(?:sq\s*ft|square\s*feet)/i)
    if size_range_match
      entities[:size_range] = {
        min: size_range_match[1].to_i,
        max: size_range_match[2].to_i
      }
    end

    entities
  end

  def clean_price(price_string)
    return nil unless price_string
    price_string.gsub(/[,$]/, "").to_i
  end

  def clean_location(location_string)
    return nil unless location_string
    location_string.strip.gsub(/[,.]$/, "")
  end

  def determine_urgency_level(urgency_matches)
    return :normal if urgency_matches.empty?

    urgency_levels = {
      "emergency" => :emergency,
      "urgent" => :high,
      "asap" => :high,
      "immediately" => :high,
      "right now" => :high
    }

    urgency_matches.map { |match| urgency_levels[match.downcase] || :medium }.max
  end

  def parse_timeline(timeline_matches)
    return nil if timeline_matches.empty?

    number = timeline_matches[0].to_i
    unit = timeline_matches[1]&.downcase

    case unit
    when "day", "days"
      number.days.from_now
    when "week", "weeks"
      number.weeks.from_now
    when "month", "months"
      number.months.from_now
    when "year", "years"
      number.years.from_now
    else
      nil
    end
  end

  def parse_date(date_string)
    Date.parse(date_string)
  rescue Date::Error
    nil
  end
end
