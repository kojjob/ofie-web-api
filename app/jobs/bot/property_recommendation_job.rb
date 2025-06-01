# Job for generating personalized property recommendations
class Bot::PropertyRecommendationJob < ApplicationJob
  queue_as :bot_recommendations

  def perform(user_id, search_entities = {})
    user = User.find(user_id)
    return unless user.tenant?

    begin
      # Generate recommendations based on entities and user history
      recommendations = PropertyRecommendationEngine.new(user).recommend(search_entities)

      if recommendations.any?
        # Create a proactive bot message with recommendations
        create_recommendation_message(user, recommendations, search_entities)

        # Update user preferences based on search
        update_user_preferences(user, search_entities)
      end

    rescue StandardError => e
      Rails.logger.error "Property recommendation generation failed: #{e.message}"
    end
  end

  private

  def create_recommendation_message(user, recommendations, search_entities)
    # Find or create general bot conversation
    conversation = find_or_create_bot_conversation(user)

    # Generate recommendation message
    message_content = build_recommendation_message(recommendations, search_entities)

    # Create bot message
    bot_message = Message.create!(
      conversation: conversation,
      sender: Bot.primary_bot,
      content: message_content,
      message_type: "text",
      metadata: {
        type: "property_recommendations",
        property_ids: recommendations.pluck(:id),
        search_entities: search_entities,
        generated_at: Time.current
      }
    )

    # Broadcast to user if they're online
    broadcast_recommendation(conversation, bot_message, recommendations)
  end

  def find_or_create_bot_conversation(user)
    bot_user = Bot.primary_bot

    # Find existing general conversation with bot
    conversation = Conversation.find_by(
      tenant: user,
      landlord: bot_user,
      property: nil
    )

    return conversation if conversation

    # Create new conversation
    Conversation.create!(
      tenant: user,
      landlord: bot_user,
      property: nil,
      subject: "Property Recommendations",
      status: "active"
    )
  end

  def build_recommendation_message(recommendations, search_entities)
    message = "🏠 **I found some great properties for you!**\n\n"

    if search_entities.any?
      message += "Based on your search for:\n"
      search_entities.each do |key, value|
        message += "• #{format_search_entity(key, value)}\n"
      end
      message += "\n"
    end

    message += "Here are my top recommendations:\n\n"

    recommendations.first(3).each_with_index do |property, index|
      message += format_property_recommendation(property, index + 1)
    end

    if recommendations.count > 3
      message += "\n💡 I have #{recommendations.count - 3} more properties that match your criteria. Would you like to see them?"
    end

    message += "\n\n✨ **What would you like to do next?**\n"
    message += "• Get more details about any property\n"
    message += "• Schedule viewings\n"
    message += "• Refine your search criteria\n"
    message += "• Save properties to favorites"

    message
  end

  def format_search_entity(key, value)
    case key
    when :bedroom_count
      "#{value} bedroom#{value > 1 ? 's' : ''}"
    when :bathroom_count
      "#{value} bathroom#{value > 1 ? 's' : ''}"
    when :budget
      "Budget: $#{value}"
    when :location
      "Location: #{value}"
    when :property_type
      "Type: #{value.humanize}"
    when :amenities
      "Amenities: #{Array(value).join(', ')}"
    else
      "#{key.humanize}: #{value}"
    end
  end

  def format_property_recommendation(property, index)
    card = "**#{index}. #{property.title}**\n"
    card += "📍 #{property.address}, #{property.city}\n"
    card += "💰 $#{property.price}/month • 🛏️ #{property.bedrooms} bed • 🚿 #{property.bathrooms} bath\n"

    if property.amenities_list.any?
      card += "✨ #{property.amenities_list.first(3).join(', ')}\n"
    end

    if property.average_rating > 0
      card += "⭐ #{property.average_rating}/5 (#{property.reviews_count} reviews)\n"
    end

    card += "\n"
  end

  def update_user_preferences(user, search_entities)
    # Store search entities as user preferences for future recommendations
    preferences = user.preferences || {}

    search_entities.each do |key, value|
      case key
      when :bedroom_count
        preferences[:preferred_bedrooms] = value
      when :bathroom_count
        preferences[:preferred_bathrooms] = value
      when :budget
        preferences[:budget_max] = value
      when :location
        preferences[:preferred_locations] ||= []
        preferences[:preferred_locations] << value
        preferences[:preferred_locations].uniq!
      when :property_type
        preferences[:preferred_property_types] ||= []
        preferences[:preferred_property_types] << value
        preferences[:preferred_property_types].uniq!
      when :amenities
        preferences[:preferred_amenities] ||= []
        preferences[:preferred_amenities].concat(Array(value))
        preferences[:preferred_amenities].uniq!
      end
    end

    user.update!(preferences: preferences)
  end

  def broadcast_recommendation(conversation, bot_message, recommendations)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "property_recommendations",
        data: {
          message: serialize_message(bot_message),
          properties: recommendations.first(3).map { |p| serialize_property(p) },
          total_count: recommendations.count,
          timestamp: Time.current
        }
      }
    )
  end

  def serialize_message(message)
    {
      id: message.id,
      content: message.content,
      sender_id: message.sender_id,
      sender_name: message.sender.name,
      sender_role: message.sender.role,
      message_type: message.message_type,
      created_at: message.created_at,
      metadata: message.metadata
    }
  end

  def serialize_property(property)
    {
      id: property.id,
      title: property.title,
      address: property.address,
      city: property.city,
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      property_type: property.property_type,
      amenities: property.amenities_list,
      average_rating: property.average_rating,
      reviews_count: property.reviews_count,
      photos: property.photos.attached? ? property.photos.map { |photo| rails_blob_url(photo) } : []
    }
  end
end
