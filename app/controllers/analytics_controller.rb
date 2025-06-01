class AnalyticsController < ApplicationController
  before_action :authenticate_request
  before_action :ensure_landlord

  def index
    @analytics_data = build_analytics_data
    @date_range = params[:date_range] || "30_days"
    @property_filter = params[:property_id]

    respond_to do |format|
      format.html
      format.json { render json: @analytics_data }
    end
  end

  private

  def ensure_landlord
    unless current_user.landlord?
      redirect_to dashboard_path, alert: "Access denied. Analytics are only available for landlords."
    end
  end

  def build_analytics_data
    properties = current_user.properties
    properties = properties.where(id: @property_filter) if @property_filter.present?

    date_range = get_date_range(@date_range)

    {
      overview: build_overview_stats(properties, date_range),
      properties: build_property_stats(properties, date_range),
      revenue: build_revenue_stats(properties, date_range),
      occupancy: build_occupancy_stats(properties, date_range),
      maintenance: build_maintenance_stats(properties, date_range),
      inquiries: build_inquiry_stats(properties, date_range),
      reviews: build_review_stats(properties, date_range),
      trends: build_trend_data(properties, date_range)
    }
  end

  def get_date_range(range_param)
    case range_param
    when "7_days"
      7.days.ago..Time.current
    when "30_days"
      30.days.ago..Time.current
    when "90_days"
      90.days.ago..Time.current
    when "1_year"
      1.year.ago..Time.current
    else
      30.days.ago..Time.current
    end
  end

  def build_overview_stats(properties, date_range)
    {
      total_properties: properties.count,
      occupied_properties: properties.joins(:lease_agreements).where(lease_agreements: { status: "active" }).count,
      total_revenue: calculate_total_revenue(properties, date_range),
      pending_maintenance: properties.joins(:maintenance_requests).where(maintenance_requests: { status: "pending" }).count,
      new_inquiries: count_new_inquiries(properties, date_range),
      average_rating: calculate_average_rating(properties)
    }
  end

  def build_property_stats(properties, date_range)
    properties.map do |property|
      {
        id: property.id,
        title: property.title,
        address: property.address,
        price: property.price,
        status: property.status,
        occupancy_rate: calculate_occupancy_rate(property, date_range),
        revenue: calculate_property_revenue(property, date_range),
        inquiries: count_property_inquiries(property, date_range),
        maintenance_requests: property.maintenance_requests.where(created_at: date_range).count,
        average_rating: property.property_reviews.average(:rating) || 0,
        views: count_property_views(property, date_range)
      }
    end
  end

  def build_revenue_stats(properties, date_range)
    # This would integrate with your payment system
    # For now, we'll use estimated revenue based on property prices
    monthly_revenue = properties.joins(:lease_agreements)
                               .where(lease_agreements: { status: "active" })
                               .sum(:price)

    {
      monthly_revenue: monthly_revenue,
      yearly_projection: monthly_revenue * 12,
      revenue_trend: build_revenue_trend(properties, date_range),
      payment_status: {
        collected: monthly_revenue * 0.85, # Estimated
        pending: monthly_revenue * 0.15    # Estimated
      }
    }
  end

  def build_occupancy_stats(properties, date_range)
    total_properties = properties.count
    occupied = properties.joins(:lease_agreements).where(lease_agreements: { status: "active" }).count

    {
      total_units: total_properties,
      occupied_units: occupied,
      vacant_units: total_properties - occupied,
      occupancy_rate: total_properties > 0 ? (occupied.to_f / total_properties * 100).round(2) : 0,
      occupancy_trend: build_occupancy_trend(properties, date_range)
    }
  end

  def build_maintenance_stats(properties, date_range)
    maintenance_requests = MaintenanceRequest.joins(:property)
                                           .where(properties: { user_id: current_user.id })
                                           .where(created_at: date_range)

    {
      total_requests: maintenance_requests.count,
      pending: maintenance_requests.where(status: "pending").count,
      in_progress: maintenance_requests.where(status: "in_progress").count,
      completed: maintenance_requests.where(status: "completed").count,
      average_resolution_time: calculate_average_resolution_time(maintenance_requests),
      cost_estimate: maintenance_requests.sum(:estimated_cost) || 0
    }
  end

  def build_inquiry_stats(properties, date_range)
    # This would track property inquiries/messages
    conversations = Conversation.joins(:property)
                               .where(properties: { user_id: current_user.id })
                               .where(created_at: date_range)

    {
      total_inquiries: conversations.count,
      response_rate: calculate_response_rate(conversations),
      average_response_time: calculate_average_response_time(conversations),
      conversion_rate: calculate_conversion_rate(conversations)
    }
  end

  def build_review_stats(properties, date_range)
    reviews = PropertyReview.joins(:property)
                           .where(properties: { user_id: current_user.id })
                           .where(created_at: date_range)

    {
      total_reviews: reviews.count,
      average_rating: reviews.average(:rating) || 0,
      rating_distribution: build_rating_distribution(reviews),
      recent_reviews: reviews.order(created_at: :desc).limit(5).includes(:property, :user)
    }
  end

  def build_trend_data(properties, date_range)
    {
      revenue_trend: build_revenue_trend(properties, date_range),
      occupancy_trend: build_occupancy_trend(properties, date_range),
      inquiry_trend: build_inquiry_trend(properties, date_range),
      maintenance_trend: build_maintenance_trend(properties, date_range)
    }
  end

  # Helper methods for calculations
  def calculate_total_revenue(properties, date_range)
    # This would integrate with your payment system
    properties.joins(:lease_agreements)
             .where(lease_agreements: { status: "active" })
             .sum(:price)
  end

  def calculate_property_revenue(property, date_range)
    # This would integrate with your payment system
    property.lease_agreements.where(status: "active").sum(&:monthly_rent) || property.price
  end

  def calculate_occupancy_rate(property, date_range)
    # Simple calculation - in reality this would be more complex
    property.lease_agreements.where(status: "active").any? ? 100 : 0
  end

  def count_new_inquiries(properties, date_range)
    Conversation.joins(:property)
               .where(properties: { user_id: current_user.id })
               .where(created_at: date_range)
               .count
  end

  def count_property_inquiries(property, date_range)
    property.conversations.where(created_at: date_range).count
  end

  def count_property_views(property, date_range)
    # This would track property page views
    # For now, return a placeholder
    rand(50..200)
  end

  def calculate_average_rating(properties)
    reviews = PropertyReview.joins(:property).where(properties: { user_id: current_user.id })
    reviews.average(:rating) || 0
  end

  def calculate_average_resolution_time(maintenance_requests)
    completed = maintenance_requests.where(status: "completed")
    return 0 if completed.empty?

    total_time = completed.sum do |request|
      (request.updated_at - request.created_at) / 1.day
    end

    (total_time / completed.count).round(1)
  end

  def calculate_response_rate(conversations)
    return 0 if conversations.empty?

    responded = conversations.joins(:messages)
                           .where(messages: { sender_id: current_user.id })
                           .distinct
                           .count

    (responded.to_f / conversations.count * 100).round(2)
  end

  def calculate_average_response_time(conversations)
    # This would calculate actual response times
    # For now, return a placeholder
    rand(2..24)
  end

  def calculate_conversion_rate(conversations)
    # This would track how many inquiries convert to leases
    # For now, return a placeholder
    rand(15..35)
  end

  def build_rating_distribution(reviews)
    (1..5).map do |rating|
      {
        rating: rating,
        count: reviews.where(rating: rating).count
      }
    end
  end

  def build_revenue_trend(properties, date_range)
    # This would build actual revenue trend data
    # For now, return sample data
    []
  end

  def build_occupancy_trend(properties, date_range)
    # This would build actual occupancy trend data
    # For now, return sample data
    []
  end

  def build_inquiry_trend(properties, date_range)
    # This would build actual inquiry trend data
    # For now, return sample data
    []
  end

  def build_maintenance_trend(properties, date_range)
    # This would build actual maintenance trend data
    # For now, return sample data
    []
  end
end
