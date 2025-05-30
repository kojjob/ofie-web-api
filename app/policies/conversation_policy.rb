class ConversationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present? && participant?
  end

  def create?
    user.present? && can_create_conversation?
  end

  def update?
    user.present? && participant?
  end

  def destroy?
    user.present? && participant?
  end

  class Scope < Scope
    def resolve
      if user.present?
        scope.where(
          "landlord_id = ? OR tenant_id = ?",
          user.id, user.id
        )
      else
        scope.none
      end
    end
  end

  private

  def participant?
    return false unless record && user
    record.landlord_id == user.id || record.tenant_id == user.id
  end

  def can_create_conversation?
    # Additional logic can be added here for conversation creation rules
    # For now, any authenticated user can create conversations
    true
  end
end
