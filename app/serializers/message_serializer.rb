class MessageSerializer < ActiveModel::Serializer
  attributes :id, :content, :message_type, :read, :read_at, :attachment_url,
             :created_at, :updated_at, :is_own_message

  belongs_to :sender, serializer: UserSerializer
  belongs_to :conversation, serializer: ConversationSerializer, if: :include_conversation?

  def is_own_message
    return false unless current_user
    object.sender_id == current_user.id
  end

  def read
    return true if is_own_message
    object.read?
  end

  def read_at
    return nil if is_own_message
    object.read_at
  end

  private

  def current_user
    scope
  end

  def include_conversation?
    # Only include conversation details if specifically requested
    # to avoid circular references and reduce payload size
    instance_options[:include_conversation] == true
  end
end
