class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :content, presence: true
  validates :message_type, presence: true, inclusion: { in: %w[text image file] }

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }

  after_create :update_conversation_timestamp
  after_create :create_notification

  def mark_as_read!
    return if read?
    update!(read: true, read_at: Time.current)
  end

  def recipient
    conversation.other_participant(sender)
  end

  private

  def update_conversation_timestamp
    conversation.update_last_message_time!
  end

  def create_notification
    Notification.create_message_notification(recipient, sender, content)
  rescue => e
    Rails.logger.error "Failed to create message notification: #{e.message}"
  end
end
