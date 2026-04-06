class DebtSimplifier
  def initialize(net_balances_cents:)
    @net_balances_cents = net_balances_cents
  end

  def call
    debtors = @net_balances_cents.filter_map { |user_id, cents| [ user_id, -cents ] if cents.negative? }
    creditors = @net_balances_cents.filter_map { |user_id, cents| [ user_id, cents ] if cents.positive? }

    debtor_idx = 0
    creditor_idx = 0
    simplified = []

    while debtor_idx < debtors.length && creditor_idx < creditors.length
      debtor_id, debtor_owed = debtors[debtor_idx]
      creditor_id, creditor_due = creditors[creditor_idx]

      transfer_cents = [ debtor_owed, creditor_due ].min
      simplified << { from_user_id: debtor_id, to_user_id: creditor_id, amount: MoneyUtils.from_cents(transfer_cents) }

      debtors[debtor_idx][1] -= transfer_cents
      creditors[creditor_idx][1] -= transfer_cents

      debtor_idx += 1 if debtors[debtor_idx][1].zero?
      creditor_idx += 1 if creditors[creditor_idx][1].zero?
    end

    simplified
  end
end
