class GroupSerializer < ApplicationSerializer
  def as_json
    {
      id: resource.id,
      name: resource.name,
      creator: UserSerializer.render(resource.creator),
      members: UserSerializer.render(resource.members.order(:id)),
      created_at: resource.created_at,
      updated_at: resource.updated_at
    }
  end
end
