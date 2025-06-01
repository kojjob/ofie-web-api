# Comprehensive MaintenanceRequest authorization policy
class MaintenanceRequestPolicy < ApplicationPolicy
  def index?
    user.present? && (user.landlord? || user.tenant?)
  end

  def show?
    tenant? || landlord? || assigned_contractor? || admin?
  end

  def create?
    user.present? && user.tenant? && has_active_lease?
  end

  def update?
    tenant? && updatable_status? || landlord? || assigned_contractor?
  end

  def destroy?
    tenant? && pending? || landlord? || admin?
  end

  def assign?
    landlord? || admin?
  end

  def update_status?
    landlord? || assigned_contractor? || admin?
  end

  def mark_complete?
    assigned_contractor? || landlord? || admin?
  end

  def view_cost_estimates?
    landlord? || assigned_contractor? || admin?
  end

  def emergency_override?
    admin? || (landlord? && emergency_priority?)
  end

  private

  def tenant?
    user.present? && record.tenant == user
  end

  def landlord?
    user.present? && record.landlord == user
  end

  def assigned_contractor?
    user.present? && record.assigned_to == user
  end

  def admin?
    user.present? && user.admin?
  end

  def has_active_lease?
    record&.property&.lease_agreements&.active&.exists?(tenant: user)
  end

  def pending?
    record.status == "pending"
  end

  def updatable_status?
    %w[pending].include?(record.status)
  end

  def emergency_priority?
    record.priority == "emergency"
  end

  class Scope < Scope
    def resolve
      if user&.landlord?
        # Landlords see requests for their properties
        scope.where(landlord: user)
      elsif user&.tenant?
        # Tenants see only their own requests
        scope.where(tenant: user)
      elsif user&.contractor?
        # Contractors see assigned requests
        scope.where(assigned_to: user)
      else
        scope.none
      end
    end
  end
end
