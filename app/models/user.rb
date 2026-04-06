class User < ApplicationRecord
  has_secure_password

  has_many :created_groups, class_name: "Group", foreign_key: :creator_id, inverse_of: :creator, dependent: :nullify
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :paid_expenses, class_name: "Expense", foreign_key: :payer_id, inverse_of: :payer, dependent: :nullify
  has_many :expense_splits, dependent: :destroy
  has_many :outgoing_settlements, class_name: "Settlement", foreign_key: :from_user_id, inverse_of: :from_user, dependent: :nullify
  has_many :incoming_settlements, class_name: "Settlement", foreign_key: :to_user_id, inverse_of: :to_user, dependent: :nullify
  has_many :activities, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end
end
