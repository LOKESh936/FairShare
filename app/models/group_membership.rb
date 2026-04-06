class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  enum role: { member: 0, admin: 1 }, _default: :member

  validates :user_id, uniqueness: { scope: :group_id }
end
