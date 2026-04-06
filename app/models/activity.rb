class Activity < ApplicationRecord
  ACTION_TYPES = %w[expense_created settlement_created].freeze

  belongs_to :group
  belongs_to :actor, class_name: "User", inverse_of: :activities
  belongs_to :trackable, polymorphic: true

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
end
