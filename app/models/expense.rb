class Expense < ApplicationRecord
  belongs_to :group
  belongs_to :payer, class_name: "User", inverse_of: :paid_expenses
  has_many :expense_splits, dependent: :destroy
  has_one :activity, as: :trackable, dependent: :destroy

  enum split_type: { equal: 0, custom: 1 }, _default: :equal

  validates :description, presence: true
  validates :amount, numericality: { greater_than: 0 }
  validates :split_type, presence: true
  validate :payer_must_be_group_member

  private

  def payer_must_be_group_member
    return if group.blank? || payer.blank? || group.member?(payer)

    errors.add(:payer_id, "must belong to the group")
  end
end
