# PropertyInquiriesController
# Handles landlord management of property inquiries
# Allows landlords to view, respond to, and manage inquiries for their properties
class PropertyInquiriesController < ApplicationController
  layout "dashboard"
  before_action :authenticate_request
  before_action :authorize_landlord!
  before_action :set_inquiry, only: [ :show, :mark_read, :mark_responded, :archive, :unarchive ]
  before_action :authorize_inquiry_access, only: [ :show, :mark_read, :mark_responded, :archive, :unarchive ]

  # GET /property_inquiries
  def index
    @inquiries = PropertyInquiry.for_landlord(current_user.id)
                                .includes(:property)
                                .recent

    # Apply filters
    @inquiries = @inquiries.where(status: params[:status]) if params[:status].present?
    @inquiries = @inquiries.where(property_id: params[:property_id]) if params[:property_id].present?

    # Pagination
    @inquiries = @inquiries.page(params[:page]).per(20)

    # Load user's properties for filter dropdown
    @properties = current_user.properties.order(:title)
  end

  # GET /property_inquiries/:id
  def show
    # Automatically mark as read when viewed
    @inquiry.mark_as_read! if @inquiry.unread?
  end

  # POST /property_inquiries/:id/mark_read
  def mark_read
    @inquiry.mark_as_read!
    redirect_back fallback_location: property_inquiries_path, notice: "Inquiry marked as read."
  end

  # POST /property_inquiries/:id/mark_responded
  def mark_responded
    @inquiry.mark_as_responded!
    redirect_back fallback_location: property_inquiries_path, notice: "Inquiry marked as responded."
  end

  # POST /property_inquiries/:id/archive
  def archive
    @inquiry.archive!
    redirect_back fallback_location: property_inquiries_path, notice: "Inquiry archived."
  end

  # POST /property_inquiries/:id/unarchive
  def unarchive
    @inquiry.update!(status: :pending)
    redirect_back fallback_location: property_inquiries_path, notice: "Inquiry restored."
  end

  private

  def set_inquiry
    @inquiry = PropertyInquiry.find(params[:id])
  end

  def authorize_landlord!
    unless current_user.landlord?
      redirect_to dashboard_path, alert: "Only landlords can access property inquiries."
    end
  end

  def authorize_inquiry_access
    # Ensure the inquiry belongs to one of the landlord's properties
    unless @inquiry.property.user_id == current_user.id
      redirect_to property_inquiries_path, alert: "You don't have permission to #{action_permission_message}."
    end
  end

  def action_permission_message
    case action_name
    when "show"
      "view this inquiry"
    else
      "update this inquiry"
    end
  end
end
