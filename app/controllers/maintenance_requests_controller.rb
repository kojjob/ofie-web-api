class MaintenanceRequestsController < ApplicationController
  before_action :authenticate_request
  before_action :set_maintenance_request, only: [ :show, :edit, :update, :destroy ]

  # GET /maintenance_requests
  def index
    @maintenance_requests = current_user_maintenance_requests
                           .includes(:property, :tenant, :landlord, :assigned_to, photos_attachments: :blob)
                           .order(requested_at: :desc)
                           .page(params[:page])
                           .per(20)
  end

  # GET /maintenance_requests/:id
  def show
    unless can_access_request?(@maintenance_request)
      redirect_to maintenance_requests_path, alert: "Access denied"
      nil
    end
  end

  # GET /maintenance_requests/new
  def new
    @maintenance_request = MaintenanceRequest.new
    @properties = current_user_properties
  end

  # POST /maintenance_requests
  def create
    @property = Property.find(params[:property_id]) if params[:property_id]

    unless @property && can_create_request_for_property?(@property)
      redirect_to maintenance_requests_path, alert: "Access denied"
      return
    end

    @maintenance_request = @property.maintenance_requests.build(maintenance_request_params)
    @maintenance_request.tenant = current_user

    if @maintenance_request.save
      attach_photos if params[:photos].present?
      redirect_to @maintenance_request, notice: "Maintenance request created successfully"
    else
      @properties = current_user_properties
      render :new, status: :unprocessable_entity
    end
  end

  # GET /maintenance_requests/:id/edit
  def edit
    unless can_access_request?(@maintenance_request)
      redirect_to maintenance_requests_path, alert: "Access denied"
      nil
    end
  end

  # PATCH/PUT /maintenance_requests/:id
  def update
    unless can_access_request?(@maintenance_request)
      redirect_to maintenance_requests_path, alert: "Access denied"
      return
    end

    if @maintenance_request.update(update_maintenance_request_params)
      attach_photos if params[:photos].present?
      redirect_to @maintenance_request, notice: "Maintenance request updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /maintenance_requests/:id
  def destroy
    unless can_access_request?(@maintenance_request) && @maintenance_request.can_be_cancelled?
      redirect_to maintenance_requests_path, alert: "Cannot cancel this request"
      return
    end

    @maintenance_request.update(status: "cancelled")
    redirect_to maintenance_requests_path, notice: "Maintenance request cancelled"
  end

  # POST /maintenance_requests/:id/complete
  def complete
    unless current_user == @maintenance_request.landlord
      redirect_to @maintenance_request, alert: "Only landlords can complete requests"
      return
    end

    if @maintenance_request.can_be_completed?
      @maintenance_request.update(
        status: "completed",
        completed_at: Time.current,
        completion_notes: params[:completion_notes]
      )
      redirect_to @maintenance_request, notice: "Request marked as completed"
    else
      redirect_to @maintenance_request, alert: "Cannot complete request in current status"
    end
  end

  # POST /maintenance_requests/:id/schedule
  def schedule
    unless current_user == @maintenance_request.landlord
      redirect_to @maintenance_request, alert: "Only landlords can schedule requests"
      return
    end

    if @maintenance_request.update(
      status: "scheduled",
      scheduled_at: params[:scheduled_at],
      assigned_to_id: params[:assigned_to_id],
      landlord_notes: params[:landlord_notes]
    )
      redirect_to @maintenance_request, notice: "Request scheduled successfully"
    else
      redirect_to @maintenance_request, alert: "Failed to schedule request"
    end
  end

  private

  def set_maintenance_request
    @maintenance_request = MaintenanceRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to maintenance_requests_path, alert: "Maintenance request not found"
  end

  def current_user_maintenance_requests
    if current_user.landlord?
      current_user.landlord_maintenance_requests
    else
      current_user.tenant_maintenance_requests
    end
  end

  def current_user_properties
    if current_user.tenant?
      # Get properties where user has active leases
      Property.joins(:lease_agreements)
              .where(lease_agreements: { tenant: current_user, status: "active" })
              .distinct
    else
      current_user.properties
    end
  end

  def can_access_request?(request)
    request.tenant == current_user ||
    request.landlord == current_user ||
    request.assigned_to == current_user
  end

  def can_create_request_for_property?(property)
    if current_user.tenant?
      property.lease_agreements.active.exists?(tenant: current_user)
    else
      property.user == current_user
    end
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
end
