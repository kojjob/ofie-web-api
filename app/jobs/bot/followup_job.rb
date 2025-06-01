# Job for sending follow-up messages and checking on user engagement
class Bot::FollowupJob < ApplicationJob
  queue_as :bot_followups

  def perform(conversation_id, followup_type)
    conversation = Conversation.find(conversation_id)
    return unless conversation.landlord.bot?

    # Check if user has been active since last bot message
    return if user_has_been_active?(conversation)

    # Generate appropriate follow-up message
    followup_message = generate_followup_message(conversation, followup_type)

    if followup_message
      # Create follow-up message
      bot_message = Message.create!(
        conversation: conversation,
        sender: Bot.primary_bot,
        content: followup_message,
        message_type: "text",
        metadata: {
          type: "followup_message",
          followup_type: followup_type,
          generated_at: Time.current
        }
      )

      # Broadcast follow-up message
      broadcast_followup_message(conversation, bot_message, followup_type)
    end
  end

  private

  def user_has_been_active?(conversation)
    # Check if user has sent messages, viewed properties, or taken other actions
    last_bot_message = conversation.messages
                                  .where(sender: Bot.primary_bot)
                                  .order(created_at: :desc)
                                  .first

    return false unless last_bot_message

    # Check for user messages after last bot message
    user_messages_after = conversation.messages
                                     .where(sender: conversation.tenant)
                                     .where("created_at > ?", last_bot_message.created_at)
                                     .exists?

    # Check for other user activity
    recent_activity = check_user_recent_activity(conversation.tenant, last_bot_message.created_at)

    user_messages_after || recent_activity
  end

  def check_user_recent_activity(user, since_time)
    # Check various user activities
    activities = [
      user.property_viewings.where("created_at > ?", since_time).exists?,
      user.tenant_rental_applications.where("created_at > ?", since_time).exists?,
      user.property_favorites.where("created_at > ?", since_time).exists?,
      user.property_reviews.where("created_at > ?", since_time).exists?
    ]

    activities.any?
  end

  def generate_followup_message(conversation, followup_type)
    user = conversation.tenant
    personality = Bot::PersonalityEngine.new(user: user)

    case followup_type
    when "property_search_advanced"
      generate_search_followup(conversation, personality)
    when "application_guidance"
      generate_application_followup(conversation, personality)
    when "maintenance_intelligent"
      generate_maintenance_followup(conversation, personality)
    when "human_handoff_followup"
      generate_human_handoff_followup(conversation, personality)
    when "weekly_checkin"
      generate_weekly_checkin(conversation, personality)
    when "onboarding_completion"
      generate_onboarding_completion(conversation, personality)
    else
      generate_general_followup(conversation, personality)
    end
  end

  def generate_search_followup(conversation, personality)
    user = conversation.tenant

    # Check if user has found anything since our last interaction
    recent_favorites = user.property_favorites.where("created_at > ?", 1.day.ago).count
    recent_viewings = user.property_viewings.where("created_at > ?", 1.day.ago).count

    if recent_favorites > 0 || recent_viewings > 0
      return "🎉 I see you've been exploring some properties! How's the search going? Need help with anything specific? I'm here whenever you need guidance!"
    end

    base_message = "👋 Hey there! Just checking in on your property search. "

    followup_options = [
      "Have you had a chance to look at those recommendations I shared? I'd love to hear your thoughts!",
      "Still searching for the perfect place? I can help refine your criteria or show you some new listings that just came up!",
      "Found anything interesting yet? I'm here if you want to discuss any properties or need help with next steps!",
      "How's the hunt going? If you haven't found what you're looking for, I can suggest some new approaches!"
    ]

    suggestions = [
      "\n\n💡 **Quick options:**",
      "• See new properties in your area",
      "• Refine your search criteria",
      "• Get neighborhood insights",
      "• Schedule property viewings"
    ]

    base_message + followup_options.sample + suggestions.join("\n")
  end

  def generate_application_followup(conversation, personality)
    user = conversation.tenant

    # Check application status
    recent_applications = user.tenant_rental_applications.where("created_at > ?", 3.days.ago)

    if recent_applications.any?
      pending_count = recent_applications.pending.count
      under_review_count = recent_applications.under_review.count

      if pending_count > 0 || under_review_count > 0
        return "📋 Quick check-in on your applications! You have #{pending_count + under_review_count} application(s) under review. " \
               "Remember to keep your phone handy in case landlords need additional info. Need help with anything while you wait?"
      end
    end

    base_messages = [
      "📝 How did your rental application go? I'm here if you need help with any part of the process!",
      "🏠 Following up on our rental application chat - do you have any questions about next steps?",
      "📋 Hope your application process is going smoothly! Let me know if you need guidance on anything!"
    ]

    tips = [
      "\n\n💡 **Application tips:**",
      "• Follow up politely if you haven't heard back in 5-7 days",
      "• Keep working on backup options",
      "• Have your documents ready for quick responses",
      "• Stay positive - the right place will come along!"
    ]

    base_messages.sample + tips.join("\n")
  end

  def generate_maintenance_followup(conversation, personality)
    user = conversation.tenant

    # Check recent maintenance requests
    recent_requests = user.tenant_maintenance_requests.where("created_at > ?", 1.day.ago)

    if recent_requests.any?
      emergency_requests = recent_requests.emergency
      in_progress_requests = recent_requests.in_progress

      if emergency_requests.any?
        return "🚨 Checking in on your emergency maintenance request. Has it been resolved? If you're still having issues, please contact your landlord directly or call emergency services if it's a safety concern."
      elsif in_progress_requests.any?
        return "🔧 Just wanted to check - how's the progress on your maintenance request? Is everything moving along as expected? Let me know if you need help communicating with your landlord!"
      end
    end

    followup_messages = [
      "🔧 Hope your maintenance issue got resolved quickly! Everything working properly now?",
      "🏠 Following up on our maintenance chat - is everything fixed up and working well?",
      "🔧 Quick check-in: how did the repair work go? Any other maintenance needs I can help you with?"
    ]

    prevention_tips = [
      "\n\n💡 **Maintenance tip:** Regular maintenance prevents bigger problems! Here are some quick checks:",
      "• Test smoke detectors monthly",
      "• Keep drains clear with regular cleaning",
      "• Check for small leaks before they become big problems",
      "• Report any issues early to your landlord"
    ]

    followup_messages.sample + prevention_tips.join("\n")
  end

  def generate_human_handoff_followup(conversation, personality)
    "👋 Hi again! I see you requested to speak with a human agent earlier. " \
    "Our team will get back to you as soon as possible during business hours (9 AM - 6 PM EST). " \
    "\n\nIn the meantime, I'm still here if you have any other questions I might be able to help with! " \
    "\n\n📞 **For urgent matters:**" \
    "\n• Email: support@ofie.com" \
    "\n• Phone: 1-800-OFIE-HELP"
  end

  def generate_weekly_checkin(conversation, personality)
    user = conversation.tenant
    greeting = personality.get_greeting

    # Analyze user's week
    this_week_activity = analyze_weekly_activity(user)

    message = "#{greeting}\n\n📊 **Your Week in Review:**\n"

    if this_week_activity[:properties_viewed] > 0
      message += "🏠 You viewed #{this_week_activity[:properties_viewed]} properties\n"
    end

    if this_week_activity[:applications_submitted] > 0
      message += "📝 You submitted #{this_week_activity[:applications_submitted]} applications\n"
    end

    if this_week_activity[:favorites_added] > 0
      message += "❤️ You favorited #{this_week_activity[:favorites_added]} properties\n"
    end

    if this_week_activity.values.sum == 0
      message += "Looks like you took a break from house hunting this week - that's totally fine!\n"
    end

    message += "\n🎯 **What would you like to focus on this week?**\n"
    message += "• Find new properties\n"
    message += "• Follow up on applications\n"
    message += "• Schedule viewings\n"
    message += "• Get neighborhood insights\n"
    message += "• Just chat about your housing goals"

    message
  end

  def generate_onboarding_completion(conversation, personality)
    user = conversation.tenant

    "🎉 Welcome to the Ofie community, #{user.name&.split&.first}!\n\n" \
    "You've been using the platform for a week now - how's your experience been so far?\n\n" \
    "🏠 **I'm here to help you:**\n" \
    "• Find the perfect property\n" \
    "• Navigate the application process\n" \
    "• Understand your rights as a tenant\n" \
    "• Connect with great landlords\n\n" \
    "💡 **Pro tip:** Set up search alerts so you're first to know about new properties that match your criteria!\n\n" \
    "What can I help you with today?"
  end

  def generate_general_followup(conversation, personality)
    user = conversation.tenant

    general_messages = [
      "👋 Hey there! Just wanted to check in and see how everything's going with your housing search!",
      "🏠 Hope you're having a great day! Any updates on your property hunt?",
      "✨ Hi! I'm here whenever you need help with anything housing-related. How can I assist you today?"
    ]

    general_messages.sample
  end

  def analyze_weekly_activity(user)
    week_ago = 1.week.ago

    {
      properties_viewed: user.property_viewings.where("created_at > ?", week_ago).count,
      applications_submitted: user.tenant_rental_applications.where("created_at > ?", week_ago).count,
      favorites_added: user.property_favorites.where("created_at > ?", week_ago).count,
      messages_sent: user.sent_messages.where("created_at > ?", week_ago).count
    }
  end

  def broadcast_followup_message(conversation, bot_message, followup_type)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "followup_message",
        data: {
          message: serialize_message(bot_message),
          followup_type: followup_type,
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
end
