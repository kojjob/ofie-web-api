class ConversationSerializer < ActiveModel::Serializer
  attributes :id, :subject, :status, :created_at, :updated_at, :last_message_at,
             :unread_count, :last_message_preview

  belongs_to :landlord, serializer: UserSerializer
  belongs_to :tenant, serializer: UserSerializer
  belongs_to :property, serializer: PropertySerializer
  has_many :messages, serializer: MessageSerializer

  def unread_count
    return 0 unless current_user
    object.unread_count_for(current_user)
  end

  def last_message_preview
    last_message = object.messages.order(:created_at).last
    return nil unless last_message

    {
      id: last_message.id,
      content: truncate_content(last_message.content),
      sender_name: last_message.sender.name || last_message.sender.email,
      created_at: last_message.created_at,
      message_type: last_message.message_type
    }
  end

  private

  def current_user
    scope
  end

  def truncate_content(content)
    return content if content.length <= 100
    "#{content[0..97]}..."
  end
end
