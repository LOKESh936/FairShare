class ExpenseSplitSerializer < ApplicationSerializer
  def as_json
    {
      user: UserSerializer.render(resource.user),
      amount: format("%.2f", resource.amount.to_f)
    }
  end
end
