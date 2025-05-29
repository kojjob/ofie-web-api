class PropertiesController < ApplicationController
  before_action :set_property, only: [ :show, :edit, :update, :destroy, :remove_photo ]
  before_action :authenticate_request, only: [ :new, :create, :edit, :update, :destroy ], unless: :html_request?
  before_action :authorize_landlord, only: [ :new, :create, :edit, :update, :destroy ], if: :api_request?
  before_action :authorize_property_owner, only: [ :edit, :update, :destroy ], if: :api_request?

  # GET /properties
  def index
    @properties = Property.available
                         .includes(:user, photos_attachments: :blob)
                         .by_city(params[:city])
                         .by_property_type(params[:property_type])
                         .by_bedrooms(params[:bedrooms])
                         .by_bathrooms(params[:bathrooms])
                         .by_price_range(params[:min_price], params[:max_price])
                         .order(created_at: :desc)

    # Apply search if provided
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @properties = @properties.where(
        "title ILIKE ? OR description ILIKE ? OR address ILIKE ? OR city ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end

    respond_to do |format|
      format.html # Render the HTML view
      format.json do
        if request.xhr?
          render partial: "properties_grid", locals: { properties: @properties }
        else
          render json: {
            properties: @properties.map { |property| property_json(property) },
            meta: {
              current_page: params[:page] || 1,
              total_count: @properties.count
            }
          }
        end
      end
    end
  end

  # GET /properties/search
  def search
    query = params[:q]&.strip

    if query.blank?
      @properties = Property.none
    else
      search_term = "%#{query}%"
      @properties = Property.available
                           .includes(:user, photos_attachments: :blob)
                           .where(
                             "title ILIKE ? OR description ILIKE ? OR address ILIKE ? OR city ILIKE ?",
                             search_term, search_term, search_term, search_term
                           )
                           .limit(10)
                           .order(:title)
    end

    respond_to do |format|
      format.json do
        render json: {
          properties: @properties.map do |property|
            {
              id: property.id,
              title: property.title,
              location: "#{property.address}, #{property.city}",
              price: property.price,
              property_type: property.property_type,
              bedrooms: property.bedrooms,
              bathrooms: property.bathrooms,
              image_url: property.photos.attached? ? url_for(property.photos.first) : nil
            }
          end
        }
      end
      format.html { redirect_to properties_path(search: query) }
    end
  end

  # GET /properties/:id
  def show
    respond_to do |format|
      format.html # Render the HTML view
      format.json {
        render json: {
          property: property_json(@property, include_contact: true)
        }
      }
    end
  end

  # GET /properties/new
  def new
    @property = current_user.properties.build
  end

  # GET /properties/:id/edit
  def edit
  end

  # POST /properties
  def create
    @property = current_user.properties.build(property_params)

    if @property.save
      respond_to do |format|
        format.html {
          flash[:success] = "🎉 Property '#{@property.title}' was successfully created and is now live!"
          redirect_to @property
        }
        format.json {
          render json: {
            message: "Property created successfully",
            property: property_json(@property)
          }, status: :created
        }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:error] = "❌ Unable to create property. Please check the form for errors."
          render :new, status: :unprocessable_entity
        }
        format.json { render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /properties/:id
  def update
    if @property.update(property_params)
      respond_to do |format|
        format.html {
          flash[:success] = "✅ Property '#{@property.title}' has been successfully updated!"
          redirect_to @property
        }
        format.json {
          render json: {
            message: "Property updated successfully",
            property: property_json(@property)
          }
        }
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:error] = "❌ Failed to update property. Please review the errors below."
          render :edit, status: :unprocessable_entity
        }
        format.json { render json: { errors: @property.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/:id
  def destroy
    property_title = @property.title
    @property.destroy
    respond_to do |format|
      format.html {
        flash[:warning] = "🗑️ Property '#{property_title}' has been permanently deleted."
        redirect_to properties_path
      }
      format.json { render json: { message: "Property deleted successfully" } }
    end
  end

  # DELETE /properties/:id/remove_photo
  def remove_photo
    photo = @property.photos.find(params[:photo_id])
    photo.purge
    redirect_to edit_property_path(@property), notice: "Photo was successfully removed."
  rescue ActiveRecord::RecordNotFound
    redirect_to edit_property_path(@property), alert: "Photo not found."
  end

  # GET /properties/my_properties (for landlords)
  def my_properties
    authorize_landlord
    @properties = current_user.properties
                             .includes(photos_attachments: :blob)
                             .order(created_at: :desc)

    render json: {
      properties: @properties.map { |property| property_json(property, include_stats: true) }
    }
  end

  private

  def html_request?
    request.format.html?
  end

  def api_request?
    !request.format.html?
  end

  def set_property
    @property = Property.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Property not found" }, status: :not_found
  end

  def authorize_landlord
    unless current_user&.landlord?
      respond_to do |format|
        format.html { redirect_to properties_path, alert: "You must be a landlord to perform this action." }
        format.json { render json: { error: "Forbidden: You must be a landlord to perform this action" }, status: :forbidden }
      end
    end
  end

  def authorize_property_owner
    unless @property.user == current_user
      respond_to do |format|
        format.html { redirect_to properties_path, alert: "You can only modify your own properties." }
        format.json { render json: { error: "Forbidden: You can only modify your own properties" }, status: :forbidden }
      end
    end
  end

  def property_params
    params.require(:property).permit(
      :title, :description, :address, :city, :state, :zip_code,
      :price, :bedrooms, :bathrooms, :square_feet, :property_type, :availability_status,
      photos: []
    )
  end

  def attach_photos
    params[:photos].each do |photo|
      @property.photos.attach(photo)
    end
  end

  def property_json(property, options = {})
    json = {
      id: property.id,
      title: property.title,
      description: property.description,
      address: property.address,
      city: property.city,
      state: property.state,
      zip_code: property.zip_code,
      price: property.price,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      square_feet: property.square_feet,
      property_type: property.property_type,
      availability_status: property.availability_status,
      created_at: property.created_at,
      updated_at: property.updated_at,
      photos: property.photos.attached? ? property.photos.map { |photo| rails_blob_url(photo) } : []
    }

    if options[:include_contact]
      json[:landlord] = {
        id: property.user.id,
        email: property.user.email
      }
    end

    if options[:include_stats]
      json[:stats] = {
        views: 0, # Placeholder for future analytics
        inquiries: 0 # Placeholder for future inquiries feature
      }
    end

    json
  end
end
