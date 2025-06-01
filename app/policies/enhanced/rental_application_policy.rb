# Comprehensive RentalApplication authorization policy
class RentalApplicationPolicy < ApplicationPolicy
  def index?
    user.present? && (user.landlord? || user.tenant?)
  end

  def show?
    applicant? || property_owner? || admin?
  end

  def create?
    user.present? && user.tenant? && property_available?
  end

  def update?
    applicant? && pending_or_under_review?
  end

  def destroy?
    applicant? && pending?
  end

  def approve?
    property_owner? && under_review?
  end

  def reject?
    property_owner? && (pending? || under_review?)
  end

  def withdraw?
    applicant? && !approved?
  end

  def create_lease?
    property_owner? && approved? && no_existing_lease?
  end

  private

  def applicant?
    user.present? && record.tenant == user
  end

  def property_owner?
    user.present? && record.property.user == user
  end

  def admin?
    user.present? && user.admin?
  end

  def property_available?
    record&.property&.available_for_applications?
  end

  def pending?
    record.status == "pending"
  end

  def under_review?
    record.status == "under_review"
  end

  def pending_or_under_review?
    %w[pending under_review].include?(record.status)
  end

  def approved?
    record.status == "approved"
  end

  def no_existing_lease?
    !record.lease_agreement.present?
  end

  class Scope < Scope
    def resolve
      if user&.landlord?
        # Landlords see applications for their properties
        scope.joins(:property).where(properties: { user: user })
      elsif user&.tenant?
        # Tenants see only their own applications
        scope.where(tenant: user)
      else
        scope.none
      end
    end
  end
end
