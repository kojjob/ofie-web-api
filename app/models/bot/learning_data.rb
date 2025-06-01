# Model for storing bot learning data and interaction analytics
module Bot
  class LearningData < ApplicationRecord
    self.table_name = "bot_learning_data"

    belongs_to :user

    validates :message, presence: true
    validates :intent, presence: true
    validates :confidence, presence: true,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
    validates :session_id, presence: true

    # Store entities and context as JSON
    serialize :entities, JSON
    serialize :context, JSON

    # Scopes for analytics
    scope :high_confidence, -> { where("confidence > ?", 0.8) }
    scope :low_confidence, -> { where("confidence < ?", 0.5) }
    scope :by_intent, ->(intent) { where(intent: intent) }
    scope :recent, -> { where("created_at > ?", 30.days.ago) }

    # Analytics methods
    def self.intent_accuracy_report
      total_interactions = count
      return {} if total_interactions.zero?

      {
        total_interactions: total_interactions,
        high_confidence_percentage: (high_confidence.count.to_f / total_interactions * 100).round(2),
        low_confidence_percentage: (low_confidence.count.to_f / total_interactions * 100).round(2),
        most_common_intents: group(:intent).order("count_id DESC").limit(10).count(:id),
        average_confidence: average(:confidence).round(3)
      }
    end

    def self.user_interaction_patterns(user_id)
      user_data = where(user_id: user_id)

      {
        total_interactions: user_data.count,
        favorite_intents: user_data.group(:intent).order("count_id DESC").limit(5).count(:id),
        average_confidence: user_data.average(:confidence)&.round(3),
        session_count: user_data.distinct.count(:session_id),
        first_interaction: user_data.minimum(:created_at),
        last_interaction: user_data.maximum(:created_at)
      }
    end

    def self.improvement_opportunities
      low_confidence_intents = low_confidence
        .group(:intent)
        .order("count_id DESC")
        .limit(10)
        .count(:id)

      {
        intents_needing_improvement: low_confidence_intents,
        suggested_actions: generate_improvement_suggestions(low_confidence_intents)
      }
    end

    private

    def self.generate_improvement_suggestions(low_confidence_intents)
      suggestions = []

      low_confidence_intents.each do |intent, count|
        suggestions << {
          intent: intent,
          frequency: count,
          suggestions: [
            "Add more training patterns for #{intent}",
            "Review entity extraction for #{intent}",
            "Improve response templates for #{intent}"
          ]
        }
      end

      suggestions
    end
  end
end
