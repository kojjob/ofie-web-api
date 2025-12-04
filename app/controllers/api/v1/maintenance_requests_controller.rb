class Api::V1::MaintenanceRequestsController < ApplicationController
  before_action :authenticate_request
  before_action :set_maintenance_request, only: [ :show, :update, :destroy ]
  before_action :set_property, only: [ :index, :create ]
  before_action :authorize_access, only: [ :show, :update, :destroy ]
  before_action :authorize_property_access, only: [ :index, :create ]

  # GET /api/v1/properties/:property_id/maintenance_requests
  # GET /api/v1/maintenance_requests
  def index
    if params[:property_id]
      # Get maintenance requests for a specific property
      @maintenance_requests = @property.maintenance_requests
    else
      # Get maintenance requests for the current user
      @maintenance_requests = current_user_maintenance_requests
    end

    # Apply filters
    @maintenance_requests = apply_filters(@maintenance_requests)
    @maintenance_requests = @maintenance_requests.includes(:property, :tenant, :landlord, :assigned_to)
                                                 .with_attached_photos
                                                 .order(requested_at: :desc)
                                                 .page(params[:page])
                                                 .per(params[:per_page] || 20)

    render json: {
      maintenance_requests: @maintenance_requests.map { |request| maintenance_request_json(request) },
      meta: pagination_meta(@maintenance_requests)
    }
  end

  # GET /api/v1/maintenance_requests/:id
  def show
    render json: {
      maintenance_request: detailed_maintenance_request_json(@maintenance_request)
    }
  end

  # POST /api/v1/properties/:property_id/maintenance_requests
  def create
    @maintenance_request = @property.maintenance_requests.build(maintenance_request_params)
    @maintenance_request.tenant = current_user

    if @maintenance_request.save
      attach_photos if params[:photos].present?
      attach_documents if params[:documents].present?

      render json: {
        message: "Maintenance request created successfully",
        maintenance_request: detailed_maintenance_request_json(@maintenance_request)
      }, status: :created
    else
      render json: {
        error: "Failed to create maintenance request",
        details: @maintenance_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/maintenance_requests/:id
  def update
    if @maintenance_request.update(update_maintenance_request_params)
      attach_photos if params[:photos].present?
      attach_documents if params[:documents].present?

      render json: {
        message: "Maintenance request updated successfully",
        maintenance_request: detailed_maintenance_request_json(@maintenance_request)
      }
    else
      render json: {
        error: "Failed to update maintenance request",
        details: @maintenance_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/maintenance_requests/:id
  def destroy
    if @maintenance_request.can_be_cancelled?
      @maintenance_request.update(status: "cancelled")
      render json: { message: "Maintenance request cancelled successfully" }
    else
      render json: {
        error: "Cannot cancel maintenance request in current status"
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/maintenance_requests/:id/complete
  def complete
    set_maintenance_request
    authorize_landlord_access

    if @maintenance_request.can_be_completed?
      @maintenance_request.update(
        status: "completed",
        completed_at: Time.current,
        completion_notes: params[:completion_notes]
      )
      render json: {
        message: "Maintenance request marked as completed",
        maintenance_request: detailed_maintenance_request_json(@maintenance_request)
      }
    else
      render json: {
        error: "Cannot complete maintenance request in current status"
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/maintenance_requests/:id/schedule
  def schedule
    set_maintenance_request
    authorize_landlord_access

    if @maintenance_request.update(
      status: "scheduled",
      scheduled_at: params[:scheduled_at],
      assigned_to_id: params[:assigned_to_id],
      landlord_notes: params[:landlord_notes]
    )
      render json: {
        message: "Maintenance request scheduled successfully",
        maintenance_request: detailed_maintenance_request_json(@maintenance_request)
      }
    else
      render json: {
        error: "Failed to schedule maintenance request",
        details: @maintenance_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_maintenance_request
    @maintenance_request = MaintenanceRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Maintenance request not found" }, status: :not_found
  end

  def set_property
    @property = Property.find(params[:property_id]) if params[:property_id]
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def authorize_access
    unless @maintenance_request.tenant == current_user ||
           @maintenance_request.landlord == current_user ||
           @maintenance_request.assigned_to == current_user
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def authorize_property_access
    return unless @property

    # For tenants: must have active lease for the property
    # For landlords: must own the property
    unless (current_user.tenant? && @property.lease_agreements.active.exists?(tenant: current_user)) ||
           (current_user.landlord? && @property.user == current_user)
      render json: { error: "Access denied" }, status: :forbidden
    end
  end

  def authorize_landlord_access
    unless @maintenance_request.landlord == current_user
      render json: { error: "Only landlords can perform this action" }, status: :forbidden
    end
  end

  def current_user_maintenance_requests
    if current_user.landlord?
      current_user.landlord_maintenance_requests
    else
      current_user.tenant_maintenance_requests
    end
  end

  def apply_filters(requests)
    requests = requests.by_status(params[:status]) if params[:status].present?
    requests = requests.by_priority(params[:priority]) if params[:priority].present?
    requests = requests.by_category(params[:category]) if params[:category].present?
    requests = requests.urgent_requests if params[:urgent] == "true"
    requests = requests.overdue if params[:overdue] == "true"
    requests
  end

  def maintenance_request_params
    params.require(:maintenance_request).permit(
      :title, :description, :priority, :category, :location_details,
      :urgent, :tenant_present_required
    )
  end

  def update_maintenance_request_params
    allowed_params = [ :title, :description, :location_details, :tenant_present_required ]

    # Landlords can update additional fields
    if current_user == @maintenance_request.landlord
      allowed_params += [ :priority, :status, :estimated_cost, :scheduled_at,
                        :assigned_to_id, :landlord_notes, :completion_notes ]
    end

    params.require(:maintenance_request).permit(allowed_params)
  end

  def attach_photos
    params[:photos].each do |photo|
      @maintenance_request.photos.attach(photo)
    end
  end

  def attach_documents
    params[:documents].each do |document|
      @maintenance_request.documents.attach(document)
    end
  end

  def maintenance_request_json(request)
    {
      id: request.id,
      title: request.title,
      description: request.description,
      priority: request.priority,
      status: request.status,
      category: request.category,
      urgent: request.urgent,
      requested_at: request.requested_at,
      scheduled_at: request.scheduled_at,
      completed_at: request.completed_at,
      estimated_cost: request.estimated_cost,
      days_since_requested: request.days_since_requested.to_i,
      overdue: request.overdue?,
      property: {
        id: request.property.id,
        title: request.property.title,
        address: request.property.address
      },
      tenant: {
        id: request.tenant.id,
        name: request.tenant.name,
        email: request.tenant.email
      },
      landlord: {
        id: request.landlord.id,
        name: request.landlord.name,
        email: request.landlord.email
      },
      assigned_to: request.assigned_to ? {
        id: request.assigned_to.id,
        name: request.assigned_to.name,
        email: request.assigned_to.email
      } : nil,
      photos: request.photos.attached? ? request.photos.map { |photo| rails_blob_url(photo) } : []
    }
  end

  def detailed_maintenance_request_json(request)
    maintenance_request_json(request).merge({
      location_details: request.location_details,
      landlord_notes: request.landlord_notes,
      completion_notes: request.completion_notes,
      tenant_present_required: request.tenant_present_required,
      documents: request.documents.attached? ? request.documents.map { |doc|
        {
          id: doc.id,
          filename: doc.filename,
          url: rails_blob_url(doc)
        }
      } : []
    })
  end

  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end
end
