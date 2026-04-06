class UserSerializer < ApplicationSerializer
  def as_json
    {
      id: resource.id,
      name: resource.name,
      email: resource.email
    }
  end
end
