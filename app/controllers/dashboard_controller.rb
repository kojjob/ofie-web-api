class DashboardController < ApplicationController
  before_action :authenticate_request

  def index
    if current_user.landlord?
      landlord_dashboard
    else
      tenant_dashboard
    end
  end

  def landlord_dashboard
    @properties = current_user.properties.includes(:photos)
    @stats = {
      total_properties: @properties.count,
      available_properties: @properties.where(availability_status: "available").count,
      total_revenue: calculate_total_revenue,
      pending_applications: RentalApplication.joins(:property).where(properties: { user_id: current_user.id }, status: "pending").count
    }
    @recent_applications = RentalApplication.joins(:property)
                                          .where(properties: { user_id: current_user.id })
                                          .includes(:user, property: :photos)
                                          .order(created_at: :desc)
                                          .limit(5)
    @upcoming_payments = Payment.joins(lease_agreement: :property)
                               .where(properties: { user_id: current_user.id })
                               .where(status: "pending")
                               .where("due_date >= ?", Date.current)
                               .order(:due_date)
                               .limit(5)

    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def tenant_dashboard
    @lease_agreements = current_user.lease_agreements.includes(property: :photos)
    @stats = {
      active_leases: @lease_agreements.where(status: "active").count,
      applications_submitted: current_user.rental_applications.count,
      pending_payments: current_user.payments.where(status: "pending").count,
      favorite_properties: current_user.property_favorites.count
    }
    @recent_applications = current_user.rental_applications
                                      .includes(property: :photos)
                                      .order(created_at: :desc)
                                      .limit(5)
    @upcoming_payments = current_user.payments
                                    .where(status: "pending")
                                    .where("due_date >= ?", Date.current)
                                    .includes(lease_agreement: :property)
                                    .order(:due_date)
                                    .limit(5)
    @favorite_properties = current_user.property_favorites
                                      .includes(property: :photos)
                                      .limit(6)

    respond_to do |format|
      format.html
      format.json { render json: @stats }
    end
  end

  def analytics
    # Analytics data for landlords
    authorize_landlord!

    @analytics = {
      monthly_revenue: calculate_monthly_revenue,
      occupancy_rate: calculate_occupancy_rate,
      application_trends: calculate_application_trends,
      property_performance: calculate_property_performance
    }

    respond_to do |format|
      format.html
      format.json { render json: @analytics }
    end
  end

  private

  def calculate_total_revenue
    Payment.joins(lease_agreement: :property)
           .where(properties: { user_id: current_user.id })
           .where(status: "completed")
           .sum(:amount) || 0
  end

  def calculate_monthly_revenue
    # Calculate revenue for the last 12 months
    12.times.map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime("%b %Y"),
        revenue: Payment.joins(lease_agreement: :property)
                       .where(properties: { user_id: current_user.id })
                       .where(status: "completed")
                       .where(created_at: month..month.end_of_month)
                       .sum(:amount) || 0
      }
    end.reverse
  end

  def calculate_occupancy_rate
    total_properties = current_user.properties.count
    return 0 if total_properties.zero?

    occupied_properties = current_user.properties
                                     .joins(:lease_agreements)
                                     .where(lease_agreements: { status: "active" })
                                     .distinct
                                     .count

    (occupied_properties.to_f / total_properties * 100).round(2)
  end

  def calculate_application_trends
    # Application trends for the last 6 months
    6.times.map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime("%b %Y"),
        applications: RentalApplication.joins(:property)
                                      .where(properties: { user_id: current_user.id })
                                      .where(created_at: month..month.end_of_month)
                                      .count
      }
    end.reverse
  end

  def calculate_property_performance
    current_user.properties.includes(:rental_applications, :lease_agreements).map do |property|
      {
        id: property.id,
        title: property.title,
        applications: property.rental_applications.count,
        active_leases: property.lease_agreements.where(status: "active").count,
        total_revenue: property.lease_agreements
                              .joins(:payments)
                              .where(payments: { status: "completed" })
                              .sum("payments.amount") || 0
      }
    end
  end

  def authorize_landlord!
    redirect_to dashboard_path unless current_user.landlord?
  end

  def property_json(property)
    {
      id: property.id,
      title: property.title,
      address: property.address,
      city: property.city,
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      property_type: property.property_type,
      availability_status: property.availability_status,
      photos: property.photos.attached? ? property.photos.map { |photo| rails_blob_url(photo) } : []
    }
  end

  def application_json(application)
    {
      id: application.id,
      status: application.status,
      created_at: application.created_at,
      property: {
        id: application.property.id,
        title: application.property.title,
        address: application.property.address
      },
      applicant: {
        id: application.user.id,
        name: application.user.name,
        email: application.user.email
      }
    }
  end

  def payment_json(payment)
    {
      id: payment.id,
      amount: payment.amount,
      status: payment.status,
      payment_type: payment.payment_type,
      created_at: payment.created_at,
      due_date: payment.due_date,
      property: {
        id: payment.lease_agreement.property.id,
        title: payment.lease_agreement.property.title
      }
    }
  end

  def schedule_json(schedule)
    {
      id: schedule.id,
      amount: schedule.amount,
      due_date: schedule.due_date,
      status: schedule.status,
      payment_type: schedule.payment_type,
      property: {
        id: schedule.lease_agreement.property.id,
        title: schedule.lease_agreement.property.title
      }
    }
  end

  def lease_json(lease)
    {
      id: lease.id,
      start_date: lease.start_date,
      end_date: lease.end_date,
      monthly_rent: lease.monthly_rent,
      status: lease.status,
      property: {
        id: lease.property.id,
        title: lease.property.title,
        address: lease.property.address
      }
    }
  end
end
