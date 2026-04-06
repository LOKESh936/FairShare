class ExpenseSerializer < ApplicationSerializer
  def as_json
    {
      id: resource.id,
      description: resource.description,
      amount: format("%.2f", resource.amount.to_f),
      split_type: resource.split_type,
      payer: UserSerializer.render(resource.payer),
      splits: ExpenseSplitSerializer.render(resource.expense_splits.includes(:user)),
      created_at: resource.created_at
    }
  end
end
