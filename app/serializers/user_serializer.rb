class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :role, :created_at, :updated_at, :avatar_url

  def name
    object.name.presence || object.email
  end

  def avatar_url
    # Placeholder for avatar URL - can be implemented later
    # Could use Gravatar or uploaded avatar
    nil
  end
end
