class Settlement < ApplicationRecord
  belongs_to :group
  belongs_to :from_user, class_name: "User", inverse_of: :outgoing_settlements
  belongs_to :to_user, class_name: "User", inverse_of: :incoming_settlements
  has_one :activity, as: :trackable, dependent: :destroy

  validates :amount, numericality: { greater_than: 0 }
  validate :users_must_be_distinct
  validate :users_must_be_group_members

  private

  def users_must_be_distinct
    return if from_user_id != to_user_id

    errors.add(:to_user_id, "must be different from from_user_id")
  end

  def users_must_be_group_members
    return if group.blank? || from_user.blank? || to_user.blank?

    unless group.member?(from_user) && group.member?(to_user)
      errors.add(:base, "Both users must belong to the group")
    end
  end
end
