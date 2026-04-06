class SettlementCreator
  def initialize(group:, actor:, to_user_id:, amount:)
    @group = group
    @actor = actor
    @to_user_id = to_user_id
    @amount = amount
  end

  def call
    to_user = @group.members.find_by(id: @to_user_id)
    raise ValidationError, "Recipient user is not in this group" if to_user.nil?

    amount_cents = MoneyUtils.to_cents(@amount)
    raise ValidationError, "Amount must be greater than 0" if amount_cents <= 0

    outstanding_debt = debt_from_actor_to(to_user.id)
    if outstanding_debt <= 0
      raise ValidationError, "No outstanding debt found from #{@actor.name} to #{to_user.name}"
    end

    if amount_cents > outstanding_debt
      raise ValidationError, "Settlement amount exceeds outstanding debt"
    end

    settlement = nil
    Settlement.transaction do
      settlement = @group.settlements.create!(
        from_user: @actor,
        to_user: to_user,
        amount: MoneyUtils.from_cents(amount_cents)
      )

      Activity.create!(
        group: @group,
        actor: @actor,
        action_type: "settlement_created",
        trackable: settlement
      )
    end

    settlement
  end

  private

  def debt_from_actor_to(to_user_id)
    balances = BalanceCalculator.new(group: @group).call[:balances]
    edge = balances.find do |entry|
      entry.dig(:from_user, :id) == @actor.id && entry.dig(:to_user, :id) == to_user_id
    end
    return 0 if edge.nil?

    MoneyUtils.to_cents(edge[:amount])
  end
end
