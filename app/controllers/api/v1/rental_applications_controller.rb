class Api::V1::RentalApplicationsController < ApplicationController
  before_action :authenticate_request

  # GET /api/v1/rental_applications/approved
  def approved_for_lease
    # Only landlords can access this endpoint
    unless current_user&.landlord?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    # Get approved applications without existing leases for current user's properties
    @approved_applications = RentalApplication.joins(:property)
                                             .includes(:property, :tenant)
                                             .where(properties: { user_id: current_user.id })
                                             .where(status: "approved")
                                             .where.missing(:lease_agreement)
                                             .order(created_at: :desc)

    render json: {
      applications: @approved_applications.map { |app| approved_application_json(app) }
    }
  end

  private

  def approved_application_json(application)
    {
      id: application.id,
      tenant_name: application.tenant.name,
      tenant_email: application.tenant.email,
      property_address: "#{application.property.address}, #{application.property.city}, #{application.property.state}",
      monthly_rent: application.property.price,
      move_in_date: application.move_in_date.strftime("%B %d, %Y"),
      application_date: application.application_date.strftime("%B %d, %Y"),
      monthly_income: application.monthly_income,
      employment_status: application.employment_status,
      property: {
        id: application.property.id,
        title: application.property.title,
        address: application.property.address,
        city: application.property.city,
        state: application.property.state,
        price: application.property.price
      },
      tenant: {
        id: application.tenant.id,
        name: application.tenant.name,
        email: application.tenant.email
      }
    }
  end
end
