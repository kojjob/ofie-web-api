class PropertyFavoritesController < ApplicationController
  before_action :authenticate_request
  before_action :set_property, only: [ :create, :destroy ]
  before_action :set_property_favorite, only: [ :destroy ]

  # GET /favorites
  def index
    @favorites = current_user.property_favorites.includes(:property).order(created_at: :desc)
    @properties = @favorites.map(&:property)

    respond_to do |format|
      format.html
      format.json { render json: @favorites.includes(:property) }
    end
  end

  # POST /properties/:property_id/favorites
  def create
    @property_favorite = current_user.property_favorites.build(property: @property)

    respond_to do |format|
      if @property_favorite.save
        format.html { redirect_to @property, notice: "Property added to favorites." }
        format.json { render json: { message: "Property added to favorites", favorite: @property_favorite }, status: :created }
      else
        format.html { redirect_to @property, alert: "Unable to add property to favorites." }
        format.json { render json: { errors: @property_favorite.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/:property_id/favorites
  def destroy
    respond_to do |format|
      if @property_favorite&.destroy
        format.html { redirect_to @property, notice: "Property removed from favorites." }
        format.json { render json: { message: "Property removed from favorites" }, status: :ok }
      else
        format.html { redirect_to @property, alert: "Unable to remove property from favorites." }
        format.json { render json: { error: "Unable to remove property from favorites" }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_property
    @property = Property.find(params[:property_id])
  end

  def set_property_favorite
    @property_favorite = current_user.property_favorites.find_by(property: @property)
  end
end
