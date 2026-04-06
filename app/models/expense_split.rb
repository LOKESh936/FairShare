class ExpenseSplit < ApplicationRecord
  belongs_to :expense
  belongs_to :user

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validate :user_must_belong_to_expense_group

  private

  def user_must_belong_to_expense_group
    return if expense.blank? || user.blank? || expense.group.member?(user)

    errors.add(:user_id, "must belong to the expense group")
  end
end
