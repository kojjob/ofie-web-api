# Context Manager for maintaining conversation state and user context
class Bot::ContextManager
  include ActiveModel::Model

  attr_reader :user, :conversation, :session_id, :current_context

  def initialize(user:, conversation: nil, session_id: nil)
    @user = user
    @conversation = conversation
    @session_id = session_id || generate_session_id
    @current_context = load_context
  end

  def update_context(message)
    # Extract and update various context elements
    update_conversation_flow(message)
    update_user_preferences(message)
    update_session_state(message)
    update_temporal_context

    # Store updated context
    store_context
  end

  def get_context(key)
    @current_context[key]
  end

  def set_context(key, value)
    @current_context[key] = value
    store_context
  end

  def get_conversation_flow
    @current_context[:conversation_flow] || []
  end

  def get_user_preferences
    @current_context[:user_preferences] || {}
  end

  def get_session_data
    @current_context[:session_data] || {}
  end

  def clear_context
    @current_context = build_base_context
    store_context
  end

  def is_first_interaction?
    get_conversation_flow.empty?
  end

  def get_last_intent
    get_conversation_flow.last&.dig(:intent)
  end

  def get_search_history
    @current_context[:search_history] || []
  end

  def add_search_to_history(search_params)
    search_history = get_search_history
    search_history << {
      params: search_params,
      timestamp: Time.current,
      results_count: search_params[:results_count]
    }

    # Keep only last 10 searches
    search_history = search_history.last(10)
    set_context(:search_history, search_history)
  end

  def get_current_conversation_topic
    recent_intents = get_conversation_flow.last(3).map { |flow| flow[:intent] }

    # Determine dominant topic from recent conversation
    intent_groups = {
      property_related: [ :property_search_advanced, :property_comparison, :neighborhood_info ],
      application_related: [ :application_guidance, :lease_consultation, :legal_guidance ],
      maintenance_related: [ :maintenance_intelligent ],
      financial_related: [ :financial_planning, :market_insights ]
    }

    intent_groups.each do |topic, intents|
      return topic if (recent_intents & intents).any?
    end

    :general
  end

  def should_show_onboarding?
    @user.created_at > 1.week.ago &&
    get_conversation_flow.count < 3 &&
    !get_context(:onboarding_completed)
  end

  def mark_onboarding_completed
    set_context(:onboarding_completed, true)
  end

  def get_user_expertise_level
    # Determine user expertise based on conversation history and profile
    conversation_count = get_conversation_flow.count
    account_age_days = (Time.current - @user.created_at) / 1.day

    if account_age_days < 7 && conversation_count < 10
      :beginner
    elsif account_age_days < 30 && conversation_count < 50
      :intermediate
    else
      :experienced
    end
  end

  def get_interaction_style_preference
    # Analyze user's preferred interaction style
    recent_messages = get_conversation_flow.last(10)

    avg_message_length = recent_messages.map { |msg| msg[:message_length] }.compact.sum.to_f / recent_messages.count

    if avg_message_length < 20
      :concise
    elsif avg_message_length < 100
      :balanced
    else
      :detailed
    end
  end

  private

  def load_context
    # Try to load from cache/database
    cached_context = Rails.cache.read(context_cache_key)

    if cached_context
      cached_context
    else
      build_base_context
    end
  end

  def build_base_context
    {
      session_id: @session_id,
      user_id: @user.id,
      conversation_id: @conversation&.id,
      created_at: Time.current,
      conversation_flow: [],
      user_preferences: extract_user_preferences_from_profile,
      session_data: {},
      search_history: [],
      temporal_context: build_temporal_context,
      user_state: analyze_user_state
    }
  end

  def update_conversation_flow(message)
    flow = get_conversation_flow

    # Add current message to flow
    flow << {
      timestamp: Time.current,
      message: message,
      message_length: message.length,
      intent: nil, # Will be filled by the processor
      entities: nil, # Will be filled by the processor
      user_sentiment: nil # Will be filled by sentiment analysis
    }

    # Keep only last 20 messages in flow
    flow = flow.last(20)
    set_context(:conversation_flow, flow)
  end

  def update_user_preferences(message)
    preferences = get_user_preferences

    # Extract preferences from message (would use NLP processor)
    nlp = Bot::NaturalLanguageProcessor.new
    entities = nlp.extract_entities(message)

    # Update preferences based on entities
    if entities[:budget]
      preferences[:budget_preference] = entities[:budget]
    end

    if entities[:bedroom_count]
      preferences[:bedroom_preference] = entities[:bedroom_count]
    end

    if entities[:property_type]
      preferences[:property_type_preferences] ||= []
      preferences[:property_type_preferences] << entities[:property_type]
      preferences[:property_type_preferences].uniq!
    end

    if entities[:amenities]
      preferences[:amenity_preferences] ||= []
      preferences[:amenity_preferences].concat(entities[:amenities])
      preferences[:amenity_preferences].uniq!
    end

    set_context(:user_preferences, preferences)
  end

  def update_session_state(message)
    session_data = get_session_data

    session_data[:last_message_at] = Time.current
    session_data[:message_count] = (session_data[:message_count] || 0) + 1
    session_data[:session_duration] = Time.current - @current_context[:created_at]

    # Track engagement metrics
    session_data[:engagement_score] = calculate_engagement_score

    set_context(:session_data, session_data)
  end

  def update_temporal_context
    temporal = build_temporal_context
    set_context(:temporal_context, temporal)
  end

  def build_temporal_context
    now = Time.current

    {
      current_time: now,
      time_of_day: determine_time_of_day(now),
      day_of_week: now.strftime("%A"),
      is_weekend: now.saturday? || now.sunday?,
      is_business_hours: business_hours?(now),
      timezone: @user.timezone || "UTC"
    }
  end

  def extract_user_preferences_from_profile
    preferences = {}

    # Extract from user profile
    if @user.respond_to?(:preferred_property_type)
      preferences[:property_type_preference] = @user.preferred_property_type
    end

    # Extract from past searches/applications
    if @user.tenant?
      recent_applications = @user.tenant_rental_applications.includes(:property).limit(5)
      if recent_applications.any?
        preferences[:budget_range] = calculate_budget_range_from_applications(recent_applications)
        preferences[:location_preferences] = extract_location_preferences(recent_applications)
      end
    end

    preferences
  end

  def analyze_user_state
    {
      role: @user.role,
      account_age: Time.current - @user.created_at,
      email_verified: @user.email_verified?,
      has_properties: @user.landlord? && @user.properties.any?,
      has_applications: @user.tenant? && @user.tenant_rental_applications.any?,
      recent_activity: calculate_recent_activity
    }
  end

  def determine_time_of_day(time)
    hour = time.hour

    case hour
    when 5..11
      :morning
    when 12..17
      :afternoon
    when 18..21
      :evening
    else
      :night
    end
  end

  def business_hours?(time)
    return false if time.saturday? || time.sunday?

    hour = time.hour
    hour >= 9 && hour < 18
  end

  def calculate_engagement_score
    session_data = get_session_data
    flow = get_conversation_flow

    base_score = 50

    # Message frequency
    base_score += (session_data[:message_count] || 0) * 2

    # Session duration (points for staying engaged)
    duration_minutes = (session_data[:session_duration] || 0) / 60
    base_score += duration_minutes * 3

    # Message length variety (good engagement indicator)
    if flow.any?
      lengths = flow.map { |f| f[:message_length] }.compact
      if lengths.any?
        avg_length = lengths.sum.to_f / lengths.count
        base_score += avg_length > 20 ? 10 : 0
      end
    end

    [ base_score, 100 ].min
  end

  def calculate_budget_range_from_applications(applications)
    rents = applications.map { |app| app.property.price }.compact
    return nil if rents.empty?

    {
      min: rents.min,
      max: rents.max,
      average: rents.sum / rents.count
    }
  end

  def extract_location_preferences(applications)
    locations = applications.map { |app| app.property.city }.compact.uniq
    locations.first(3) # Top 3 preferred cities
  end

  def calculate_recent_activity
    # Count recent interactions across the platform
    recent_cutoff = 7.days.ago

    {
      messages_sent: @conversation&.messages&.where(sender: @user)&.where("created_at > ?", recent_cutoff)&.count || 0,
      properties_viewed: @user.tenant? ? @user.property_viewings.where("created_at > ?", recent_cutoff).count : 0,
      applications_submitted: @user.tenant? ? @user.tenant_rental_applications.where("created_at > ?", recent_cutoff).count : 0
    }
  end

  def generate_session_id
    "session_#{@user.id}_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
  end

  def context_cache_key
    "bot_context:#{@user.id}:#{@conversation&.id || 'global'}"
  end

  def store_context
    # Store in cache with 1 hour expiration
    Rails.cache.write(context_cache_key, @current_context, expires_in: 1.hour)

    # Also store important context in database for persistence
    BotContextStore.upsert({
      user_id: @user.id,
      conversation_id: @conversation&.id,
      session_id: @session_id,
      context_data: @current_context.slice(:user_preferences, :search_history),
      updated_at: Time.current
    }, unique_by: [ :user_id, :conversation_id ])
  rescue StandardError => e
    Rails.logger.error "Failed to store bot context: #{e.message}"
  end
end
