require "rails_helper"

RSpec.describe BalanceCalculator do
  let(:group) { create(:group, creator: user_a) }
  let(:user_a) { create(:user, name: "Ava") }
  let(:user_b) { create(:user, name: "Ben") }
  let(:user_c) { create(:user, name: "Cara") }

  before do
    [ user_a, user_b, user_c ].each_with_index do |user, idx|
      create(:group_membership, group: group, user: user, role: idx.zero? ? :admin : :member)
    end
  end

  describe "#call" do
    it "simplifies transitive debts" do
      expense_one = create(:expense, group: group, payer: user_b, amount: "10.00", split_type: :custom)
      create(:expense_split, expense: expense_one, user: user_a, amount: "10.00")

      expense_two = create(:expense, group: group, payer: user_c, amount: "10.00", split_type: :custom)
      create(:expense_split, expense: expense_two, user: user_b, amount: "10.00")

      result = described_class.new(group: group).call

      expect(result[:balances]).to eq(
        [
          {
            from_user: { id: user_a.id, name: user_a.name },
            to_user: { id: user_c.id, name: user_c.name },
            amount: "10.00"
          }
        ]
      )
    end

    it "accounts for settlements" do
      expense = create(:expense, group: group, payer: user_b, amount: "12.00", split_type: :custom)
      create(:expense_split, expense: expense, user: user_a, amount: "12.00")
      create(:settlement, group: group, from_user: user_a, to_user: user_b, amount: "4.00")

      result = described_class.new(group: group).call

      expect(result[:balances]).to eq(
        [
          {
            from_user: { id: user_a.id, name: user_a.name },
            to_user: { id: user_b.id, name: user_b.name },
            amount: "8.00"
          }
        ]
      )
    end
  end
end
