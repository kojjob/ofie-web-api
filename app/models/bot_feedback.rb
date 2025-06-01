# Model for storing user feedback on bot interactions
class BotFeedback < ApplicationRecord
  belongs_to :user
  belongs_to :message

  validates :feedback_type, presence: true,
            inclusion: { in: %w[helpful not_helpful inaccurate confusing excellent] }
  validates :details, length: { maximum: 1000 }

  serialize :context, JSON

  scope :positive_feedback, -> { where(feedback_type: %w[helpful excellent]) }
  scope :negative_feedback, -> { where(feedback_type: %w[not_helpful inaccurate confusing]) }
  scope :recent, -> { where("created_at > ?", 30.days.ago) }

  # Analytics methods
  def self.satisfaction_score
    total = count
    return 0 if total.zero?

    positive = positive_feedback.count
    (positive.to_f / total * 100).round(2)
  end

  def self.feedback_summary
    {
      total_feedback: count,
      satisfaction_score: satisfaction_score,
      feedback_breakdown: group(:feedback_type).count,
      recent_trends: recent.group(:feedback_type).count,
      common_issues: negative_feedback
                    .where.not(details: [ nil, "" ])
                    .group(:details)
                    .count
                    .sort_by { |_, count| -count }
                    .first(5)
    }
  end

  def positive?
    %w[helpful excellent].include?(feedback_type)
  end

  def negative?
    %w[not_helpful inaccurate confusing].include?(feedback_type)
  end
end
