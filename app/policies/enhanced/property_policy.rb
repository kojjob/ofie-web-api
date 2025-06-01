# Comprehensive Property authorization policy following DDD principles
class PropertyPolicy < ApplicationPolicy
  # Strong separation of concerns with clear authorization rules

  def index?
    true # Anyone can view property listings
  end

  def show?
    record.status_active? || owner? || admin?
  end

  def create?
    user.present? && user.landlord?
  end

  def update?
    owner? || admin?
  end

  def destroy?
    owner? && no_active_leases? || admin?
  end

  def manage_applications?
    owner? || admin?
  end

  def view_financials?
    owner? || admin?
  end

  def schedule_viewing?
    user.present? && user.tenant? && record.available_for_applications?
  end

  def favorite?
    user.present? && user.tenant?
  end

  def review?
    user.present? && user.tenant? && has_lease_history?
  end

  def comment?
    user.present? && (has_lease_history? || owner?)
  end

  private

  def owner?
    user.present? && record.user == user
  end

  def admin?
    user.present? && user.admin?
  end

  def no_active_leases?
    !record.lease_agreements.active.exists?
  end

  def has_lease_history?
    record.lease_agreements.where(tenant: user).exists?
  end

  class Scope < Scope
    def resolve
      if user&.landlord?
        scope.where(user: user)
      elsif user&.tenant?
        scope.status_active.available
      else
        scope.status_active.available
      end
    end
  end
end
