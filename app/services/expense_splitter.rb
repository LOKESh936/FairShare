class ExpenseSplitter
  def initialize(group:, total_amount:, split_type:, custom_splits: [])
    @group = group
    @total_cents = MoneyUtils.to_cents(total_amount)
    @split_type = split_type.to_s
    @custom_splits = custom_splits || []
  end

  def call
    raise ValidationError, "Amount must be greater than 0" if @total_cents <= 0

    case @split_type
    when "equal"
      equal_split
    when "custom"
      custom_split
    else
      raise ValidationError, "split_type must be equal or custom"
    end
  end

  private

  def equal_split
    user_ids = @group.members.order(:id).pluck(:id)
    raise ValidationError, "Group has no members" if user_ids.empty?

    base = @total_cents / user_ids.size
    remainder = @total_cents % user_ids.size

    user_ids.each_with_index.map do |user_id, idx|
      cents = base + (idx < remainder ? 1 : 0)
      { user_id: user_id, amount: MoneyUtils.from_cents(cents) }
    end
  end

  def custom_split
    raise ValidationError, "custom_splits must be provided" if @custom_splits.empty?

    member_ids = @group.members.pluck(:id)
    parsed_splits = @custom_splits.map do |entry|
      user_id = entry[:user_id] || entry["user_id"]
      amount = entry[:amount] || entry["amount"]

      raise ValidationError, "Each custom split requires user_id and amount" if user_id.blank? || amount.blank?
      raise ValidationError, "User #{user_id} is not in the group" unless member_ids.include?(user_id.to_i)

      { user_id: user_id.to_i, cents: MoneyUtils.to_cents(amount) }
    end

    if parsed_splits.map { |split| split[:user_id] }.uniq.size != parsed_splits.size
      raise ValidationError, "Duplicate users are not allowed in custom_splits"
    end

    total_custom_cents = parsed_splits.sum { |split| split[:cents] }
    if total_custom_cents != @total_cents
      raise ValidationError, "Custom splits total must equal expense amount"
    end

    parsed_splits.map { |split| { user_id: split[:user_id], amount: MoneyUtils.from_cents(split[:cents]) } }
  end
end
