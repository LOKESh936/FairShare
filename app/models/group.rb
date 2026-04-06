class Group < ApplicationRecord
  belongs_to :creator, class_name: "User", inverse_of: :created_groups

  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :expenses, dependent: :destroy
  has_many :settlements, dependent: :destroy
  has_many :activities, dependent: :destroy

  validates :name, presence: true

  def member?(user)
    group_memberships.exists?(user_id: user.id)
  end
end
