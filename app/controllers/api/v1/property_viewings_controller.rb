class Api::V1::PropertyViewingsController < ApplicationController
  before_action :authenticate_request
  before_action :set_property, only: [ :create ]
  before_action :set_viewing, only: [ :show, :update, :destroy ]

  # GET /api/v1/property_viewings
  def index
    @viewings = current_user.property_viewings.includes(:property)

    # Filter by status if provided
    @viewings = @viewings.by_status(params[:status]) if params[:status].present?

    # Filter by upcoming/past
    case params[:filter]
    when "upcoming"
      @viewings = @viewings.upcoming
    when "past"
      @viewings = @viewings.past
    end

    @viewings = @viewings.recent.page(params[:page]).per(params[:per_page] || 20)

    render json: {
      viewings: @viewings.map { |viewing| viewing_json(viewing) },
      pagination: pagination_meta(@viewings)
    }
  end

  # GET /api/v1/property_viewings/:id
  def show
    render json: { viewing: viewing_json(@viewing) }
  end

  # POST /api/v1/properties/:property_id/viewings
  def create
    @viewing = current_user.property_viewings.build(viewing_params.merge(property: @property))

    if @viewing.save
      # TODO: Send notification to property owner
      render json: {
        message: "Viewing scheduled successfully",
        viewing: viewing_json(@viewing)
      }, status: :created
    else
      render json: {
        error: "Failed to schedule viewing",
        details: @viewing.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/property_viewings/:id
  def update
    # Only allow updates to pending viewings
    unless @viewing.can_be_cancelled?
      return render json: {
        error: "Cannot update this viewing"
      }, status: :unprocessable_entity
    end

    if @viewing.update(viewing_update_params)
      render json: {
        message: "Viewing updated successfully",
        viewing: viewing_json(@viewing)
      }
    else
      render json: {
        error: "Failed to update viewing",
        details: @viewing.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/property_viewings/:id
  def destroy
    unless @viewing.can_be_cancelled?
      return render json: {
        error: "Cannot cancel this viewing"
      }, status: :unprocessable_entity
    end

    @viewing.update!(status: :cancelled)
    render json: { message: "Viewing cancelled successfully" }
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def set_viewing
    @viewing = current_user.property_viewings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Viewing not found" }, status: :not_found
  end

  def viewing_params
    params.require(:viewing).permit(:scheduled_at, :notes, :contact_phone, :contact_email)
  end

  def viewing_update_params
    params.require(:viewing).permit(:scheduled_at, :notes, :contact_phone, :contact_email, :status)
  end

  def viewing_json(viewing)
    {
      id: viewing.id,
      scheduled_at: viewing.scheduled_at,
      status: viewing.status,
      notes: viewing.notes,
      contact_phone: viewing.contact_phone,
      contact_email: viewing.contact_email,
      created_at: viewing.created_at,
      updated_at: viewing.updated_at,
      property: {
        id: viewing.property.id,
        title: viewing.property.title,
        address: viewing.property.address,
        city: viewing.property.city,
        state: viewing.property.state,
        price: viewing.property.price
      },
      can_be_cancelled: viewing.can_be_cancelled?,
      is_upcoming: viewing.upcoming?,
      is_past: viewing.past?
    }
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
