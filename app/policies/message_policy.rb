class MessagePolicy < ApplicationPolicy
  def index?
    user.present? && conversation_participant?
  end

  def show?
    user.present? && conversation_participant?
  end

  def create?
    user.present? && conversation_participant? && conversation_active?
  end

  def update?
    user.present? && (sender? || conversation_participant?)
  end

  def destroy?
    user.present? && sender?
  end

  def mark_read?
    user.present? && conversation_participant? && !sender?
  end

  def mark_all_read?
    user.present? && conversation_participant?
  end

  class Scope < Scope
    def resolve
      if user.present?
        # Return messages from conversations where user is a participant
        conversation_ids = Conversation.where(
          "landlord_id = ? OR tenant_id = ?",
          user.id, user.id
        ).pluck(:id)

        scope.where(conversation_id: conversation_ids)
      else
        scope.none
      end
    end
  end

  private

  def conversation_participant?
    return false unless record&.conversation && user

    conversation = record.conversation
    conversation.landlord_id == user.id || conversation.tenant_id == user.id
  end

  def sender?
    return false unless record && user
    record.sender_id == user.id
  end

  def conversation_active?
    return false unless record&.conversation
    record.conversation.active?
  end
end
