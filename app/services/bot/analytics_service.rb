# Analytics Service for Bot Performance and User Insights
class Bot::AnalyticsService
  include ActiveModel::Model

  class << self
    # Get comprehensive bot performance metrics
    def bot_performance_report(date_range = 30.days.ago..Time.current)
      {
        overview: generate_overview_metrics(date_range),
        intent_analysis: analyze_intent_performance(date_range),
        user_engagement: analyze_user_engagement(date_range),
        conversation_quality: analyze_conversation_quality(date_range),
        feedback_analysis: analyze_user_feedback(date_range),
        improvement_suggestions: generate_improvement_suggestions(date_range)
      }
    end

    # Get user behavior insights
    def user_behavior_analysis(user_id = nil, date_range = 30.days.ago..Time.current)
      scope = user_id ? Bot::LearningData.where(user_id: user_id) : Bot::LearningData
      data = scope.where(created_at: date_range)

      {
        interaction_patterns: analyze_interaction_patterns(data),
        preferred_intents: calculate_preferred_intents(data),
        session_analysis: analyze_session_behavior(data),
        success_metrics: calculate_success_metrics(data),
        personalization_data: extract_personalization_insights(data)
      }
    end

    # Property recommendation performance
    def recommendation_performance(date_range = 30.days.ago..Time.current)
      {
        recommendation_accuracy: calculate_recommendation_accuracy(date_range),
        click_through_rates: calculate_ctr_by_intent(date_range),
        conversion_rates: calculate_conversion_rates(date_range),
        popular_searches: get_popular_search_patterns(date_range),
        abandonment_analysis: analyze_search_abandonment(date_range)
      }
    end

    # Real-time bot metrics for dashboard
    def real_time_metrics
      {
        active_conversations: get_active_conversations_count,
        average_response_time: calculate_average_response_time,
        current_success_rate: calculate_current_success_rate,
        popular_intents_today: get_todays_popular_intents,
        user_satisfaction: get_current_satisfaction_score
      }
    end

    private

    def generate_overview_metrics(date_range)
      learning_data = Bot::LearningData.where(created_at: date_range)
      feedback_data = BotFeedback.where(created_at: date_range)

      {
        total_interactions: learning_data.count,
        unique_users: learning_data.distinct.count(:user_id),
        average_confidence: learning_data.average(:confidence)&.round(3),
        high_confidence_rate: (learning_data.where("confidence > ?", 0.8).count.to_f / learning_data.count * 100).round(2),
        user_satisfaction: calculate_satisfaction_rate(feedback_data),
        response_success_rate: calculate_response_success_rate(learning_data)
      }
    end

    def analyze_intent_performance(date_range)
      learning_data = Bot::LearningData.where(created_at: date_range)

      intent_stats = learning_data.group(:intent).group("DATE(created_at)").calculate(:average, :confidence)
      intent_counts = learning_data.group(:intent).count
      intent_feedback = get_feedback_by_intent(date_range)

      {
        intent_frequency: intent_counts.sort_by { |_, count| -count }.first(10),
        confidence_by_intent: calculate_average_confidence_by_intent(learning_data),
        success_rate_by_intent: calculate_success_rate_by_intent(intent_feedback),
        trending_intents: identify_trending_intents(learning_data),
        problematic_intents: identify_problematic_intents(learning_data, intent_feedback)
      }
    end

    def analyze_user_engagement(date_range)
      conversations = Conversation.where(updated_at: date_range)
      messages = Message.where(created_at: date_range)

      {
        conversation_length: calculate_average_conversation_length(conversations),
        session_duration: calculate_average_session_duration(date_range),
        return_user_rate: calculate_return_user_rate(date_range),
        engagement_by_time: analyze_engagement_by_time_of_day(messages),
        user_retention: calculate_user_retention_metrics(date_range)
      }
    end

    def analyze_conversation_quality(date_range)
      conversations = Conversation.joins(:messages)
                                 .where(messages: { created_at: date_range })
                                 .distinct

      {
        resolution_rate: calculate_resolution_rate(conversations),
        escalation_rate: calculate_escalation_rate(conversations),
        average_messages_per_resolution: calculate_avg_messages_to_resolution(conversations),
        common_conversation_flows: analyze_conversation_flows(conversations),
        drop_off_points: identify_conversation_drop_offs(conversations)
      }
    end

    def analyze_user_feedback(date_range)
      feedback = BotFeedback.where(created_at: date_range)

      {
        overall_satisfaction: calculate_satisfaction_score(feedback),
        feedback_distribution: feedback.group(:feedback_type).count,
        common_complaints: extract_common_complaints(feedback),
        improvement_areas: identify_improvement_areas(feedback),
        positive_feedback_themes: extract_positive_themes(feedback)
      }
    end

    def generate_improvement_suggestions(date_range)
      performance_data = {
        low_confidence_intents: get_low_confidence_intents(date_range),
        negative_feedback: get_negative_feedback_patterns(date_range),
        conversation_bottlenecks: identify_conversation_bottlenecks(date_range),
        user_drop_offs: analyze_user_drop_off_patterns(date_range)
      }

      suggestions = []

      # Generate specific improvement suggestions based on data
      performance_data[:low_confidence_intents].each do |intent|
        suggestions << {
          type: "training_improvement",
          priority: "high",
          description: "Improve training data for #{intent[:intent]} intent",
          expected_impact: "Increase confidence by 15-20%",
          implementation: "Add more training examples and refine entity extraction"
        }
      end

      performance_data[:negative_feedback].each do |pattern|
        suggestions << {
          type: "response_improvement",
          priority: "medium",
          description: "Address common complaint: #{pattern[:issue]}",
          expected_impact: "Reduce negative feedback by 10-15%",
          implementation: pattern[:suggested_solution]
        }
      end

      suggestions
    end

    # Helper methods for calculations
    def calculate_satisfaction_rate(feedback_data)
      return 0 if feedback_data.empty?

      positive_feedback = feedback_data.where(feedback_type: [ "helpful", "excellent" ]).count
      total_feedback = feedback_data.count

      (positive_feedback.to_f / total_feedback * 100).round(2)
    end

    def calculate_response_success_rate(learning_data)
      return 0 if learning_data.empty?

      successful_responses = learning_data.where("confidence > ?", 0.7).count
      total_responses = learning_data.count

      (successful_responses.to_f / total_responses * 100).round(2)
    end

    def get_active_conversations_count
      Conversation.joins(:messages)
                  .where(messages: { created_at: 1.hour.ago.. })
                  .distinct
                  .count
    end

    def calculate_average_response_time
      # Calculate based on time between user message and bot response
      bot_user = Bot.primary_bot
      recent_responses = Message.where(sender: bot_user, created_at: 24.hours.ago..)

      response_times = recent_responses.map do |bot_message|
        previous_user_message = bot_message.conversation.messages
                                          .where("created_at < ? AND sender_id != ?",
                                                bot_message.created_at, bot_user.id)
                                          .order(created_at: :desc)
                                          .first

        if previous_user_message
          bot_message.created_at - previous_user_message.created_at
        end
      end.compact

      return 0 if response_times.empty?

      (response_times.sum / response_times.count).round(2)
    end

    def calculate_current_success_rate
      recent_learning_data = Bot::LearningData.where(created_at: 24.hours.ago..)
      return 0 if recent_learning_data.empty?

      successful = recent_learning_data.where("confidence > ?", 0.7).count
      total = recent_learning_data.count

      (successful.to_f / total * 100).round(2)
    end

    def get_todays_popular_intents
      Bot::LearningData.where(created_at: Date.current.beginning_of_day..)
                       .group(:intent)
                       .order("count_id DESC")
                       .limit(5)
                       .count(:id)
    end

    def get_current_satisfaction_score
      recent_feedback = BotFeedback.where(created_at: 7.days.ago..)
      calculate_satisfaction_rate(recent_feedback)
    end
  end
end
