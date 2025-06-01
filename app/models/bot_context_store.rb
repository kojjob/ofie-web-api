# Model for storing bot conversation context and learning data
class BotContextStore < ApplicationRecord
  belongs_to :user
  belongs_to :conversation, optional: true

  validates :session_id, presence: true
  validates :context_data, presence: true

  # Store context as JSON
  serialize :context_data, JSON

  # Scope for cleanup
  scope :old_contexts, -> { where("updated_at < ?", 7.days.ago) }

  # Class method to clean up old contexts
  def self.cleanup_old_contexts
    old_contexts.delete_all
  end
end
