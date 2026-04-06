class BalanceCalculator
  def initialize(group:)
    @group = group
  end

  def call
    net_balances = Hash.new(0)

    @group.expenses.includes(:expense_splits).find_each do |expense|
      expense.expense_splits.each do |split|
        next if split.user_id == expense.payer_id

        cents = MoneyUtils.to_cents(split.amount)
        net_balances[split.user_id] -= cents
        net_balances[expense.payer_id] += cents
      end
    end

    @group.settlements.find_each do |settlement|
      cents = MoneyUtils.to_cents(settlement.amount)
      net_balances[settlement.from_user_id] += cents
      net_balances[settlement.to_user_id] -= cents
    end

    simplified = DebtSimplifier.new(net_balances_cents: net_balances).call
    users_by_id = @group.members.index_by(&:id)

    {
      balances: simplified.map do |edge|
        {
          from_user: {
            id: edge[:from_user_id],
            name: users_by_id[edge[:from_user_id]]&.name
          },
          to_user: {
            id: edge[:to_user_id],
            name: users_by_id[edge[:to_user_id]]&.name
          },
          amount: format("%.2f", edge[:amount].to_f)
        }
      end
    }
  end
end
