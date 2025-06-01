class Conversation < ApplicationRecord
  belongs_to :landlord, class_name: "User"
  belongs_to :tenant, class_name: "User"
  belongs_to :property
  has_many :messages, dependent: :destroy

  validates :subject, presence: true
  validates :status, presence: true, inclusion: { in: %w[active archived closed] }
  validates :landlord_id, uniqueness: { scope: [ :tenant_id, :property_id ] }

  scope :active, -> { where(status: "active") }
  scope :recent, -> { order(last_message_at: :desc) }
  scope :for_user, ->(user) { where("landlord_id = ? OR tenant_id = ?", user.id, user.id) }

  def other_participant(current_user)
    return nil unless current_user.id == landlord_id || current_user.id == tenant_id
    current_user.id == landlord_id ? tenant : landlord
  end

  def unread_count_for(user)
    messages.where(sender_id: other_participant(user).id, read: false).count
  end

  def mark_as_read_for(user)
    messages.where(sender_id: other_participant(user).id, read: false).update_all(read: true)
  end

  def update_last_message_time!
    update!(last_message_at: Time.current)
  end
end
