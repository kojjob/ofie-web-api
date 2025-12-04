class DashboardController < ApplicationController
  layout "dashboard"
  before_action :authenticate_request
  before_action :load_sidebar_data

  def index
    if current_user.landlord?
      landlord_dashboard
    else
      tenant_dashboard
    end
  end

  def landlord_dashboard
    # Eager load all necessary associations to avoid N+1 queries
    @properties = current_user.properties.with_attached_photos
    # Create a separate limited collection for the dashboard view
    @properties_for_display = @properties.limit(6)

    # Use more efficient queries for stats calculation
    properties_scope = current_user.properties
    @stats = {
      total_properties: properties_scope.count,
      available_properties: properties_scope.where(availability_status: "available").count,
      total_revenue: calculate_total_revenue,
      pending_applications: current_user.properties.joins(:rental_applications).where(rental_applications: { status: "pending" }).count
    }
    @recent_applications = RentalApplication.joins(:property)
                                          .where(properties: { user_id: current_user.id })
                                          .includes(:tenant, :property)
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
    @lease_agreements = current_user.tenant_lease_agreements.includes(:property).merge(Property.with_attached_photos.includes(:user))
    @stats = {
      active_leases: @lease_agreements.where(status: "active").count,
      applications_submitted: current_user.tenant_rental_applications.count,
      pending_payments: current_user.payments.where(status: "pending").count,
      favorite_properties: current_user.property_favorites.count
    }
    @recent_applications = current_user.tenant_rental_applications
                                      .includes(:property)
                                      .merge(Property.with_attached_photos)
                                      .order(created_at: :desc)
                                      .limit(5)
    @upcoming_payments = current_user.payments
                                    .where(status: "pending")
                                    .where("due_date >= ?", Date.current)
                                    .includes(lease_agreement: :property)
                                    .order(:due_date)
                                    .limit(5)
    @favorite_properties = current_user.property_favorites
                                      .includes(:property)
                                      .merge(Property.with_attached_photos)
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

  def properties
    # Properties management page for landlords
    authorize_landlord!

    @properties = current_user.properties.with_attached_photos.order(created_at: :desc)
    @stats = {
      total_properties: @properties.count,
      available_properties: @properties.where(availability_status: "available").count,
      rented_properties: @properties.where(availability_status: "rented").count,
      maintenance_properties: @properties.where(availability_status: "maintenance").count
    }

    respond_to do |format|
      format.html
      format.json { render json: { properties: @properties.map { |p| property_json(p) }, stats: @stats } }
    end
  end

  private

  def load_sidebar_data
    # Load counts for sidebar badges with safe defaults
    begin
      if current_user.landlord?
        @pending_applications_count = if defined?(RentalApplication)
                                        RentalApplication.joins(:property)
                                                       .where(properties: { user_id: current_user.id }, status: "pending")
                                                       .count
        else
                                        0
        end
        @active_leases_count = if defined?(LeaseAgreement)
                                 LeaseAgreement.joins(:property)
                                              .where(properties: { user_id: current_user.id }, status: "active")
                                              .count
        else
                                 0
        end
      else
        @favorites_count = if current_user.respond_to?(:property_favorites)
                             current_user.property_favorites.count
        else
                             0
        end
        @overdue_payments_count = if current_user.respond_to?(:payments) && defined?(Payment)
                                    current_user.payments
                                               .where("due_date < ? AND status IN (?)", Date.current, %w[pending failed])
                                               .count
        else
                                    0
        end
      end

      # Common counts for both user types
      @unread_messages_count = if current_user.respond_to?(:received_messages)
                                 current_user.received_messages.where(read: false).count
      else
                                 0
      end

      @pending_maintenance_count = if defined?(MaintenanceRequest)
                                     if current_user.landlord?
                                       MaintenanceRequest.joins(:property)
                                                        .where(properties: { user_id: current_user.id }, status: "pending")
                                                        .count
                                     else
                                       MaintenanceRequest.where(tenant_id: current_user.id, status: "pending").count
                                     end
      else
                                     0
      end

      @unread_notifications_count = if current_user.respond_to?(:notifications)
                                      current_user.notifications.where(read: false).count
      else
                                      0
      end
    rescue => e
      # Log error and set safe defaults
      Rails.logger.error "Error loading sidebar data: #{e.message}"
      @pending_applications_count = 0
      @active_leases_count = 0
      @favorites_count = 0
      @overdue_payments_count = 0
      @unread_messages_count = 0
      @pending_maintenance_count = 0
      @unread_notifications_count = 0
    end
  end

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
        id: application.tenant.id,
        name: application.tenant.name,
        email: application.tenant.email
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
