class SettlementSerializer < ApplicationSerializer
  def as_json
    {
      id: resource.id,
      from_user: UserSerializer.render(resource.from_user),
      to_user: UserSerializer.render(resource.to_user),
      amount: format("%.2f", resource.amount.to_f),
      created_at: resource.created_at
    }
  end
end
