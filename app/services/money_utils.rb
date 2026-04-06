module MoneyUtils
  module_function

  def to_cents(amount)
    (BigDecimal(amount.to_s) * 100).round(0).to_i
  end

  def from_cents(cents)
    BigDecimal(cents, 12) / 100
  end
end
