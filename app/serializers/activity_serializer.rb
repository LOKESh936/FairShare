class ActivitySerializer < ApplicationSerializer
  def as_json
    {
      id: resource.id,
      action_type: resource.action_type,
      actor: UserSerializer.render(resource.actor),
      created_at: resource.created_at,
      item: serialized_trackable
    }
  end

  private

  def serialized_trackable
    case resource.trackable
    when Expense
      ExpenseSerializer.render(resource.trackable)
    when Settlement
      SettlementSerializer.render(resource.trackable)
    else
      {}
    end
  end
end
