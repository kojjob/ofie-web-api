class PropertySerializer < ActiveModel::Serializer
  attributes :id, :title, :description, :address, :price, :property_type,
             :bedrooms, :bathrooms, :area, :status, :created_at, :updated_at

  belongs_to :user, serializer: UserSerializer

  def title
    object.title.presence || "Property at #{object.address}"
  end
end
