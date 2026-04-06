class ExpenseCreator
  def initialize(group:, creator:, params:)
    @group = group
    @creator = creator
    @params = params
  end

  def call
    split_type = @params[:split_type].presence || "equal"
    splits = ExpenseSplitter.new(
      group: @group,
      total_amount: @params[:amount],
      split_type: split_type,
      custom_splits: @params[:custom_splits]
    ).call

    expense = nil
    Expense.transaction do
      expense = @group.expenses.create!(
        payer_id: @params[:payer_id],
        description: @params[:description],
        amount: @params[:amount],
        split_type: split_type
      )

      splits.each do |split|
        expense.expense_splits.create!(split)
      end

      Activity.create!(
        group: @group,
        actor: @creator,
        action_type: "expense_created",
        trackable: expense
      )
    end

    expense
  end
end
