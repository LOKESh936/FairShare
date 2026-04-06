require "rails_helper"

RSpec.describe ExpenseSplitter do
  let(:group) { create(:group, creator: creator) }
  let(:creator) { create(:user) }
  let(:member) { create(:user) }
  let(:third_member) { create(:user) }

  before do
    create(:group_membership, group: group, user: creator, role: :admin)
    create(:group_membership, group: group, user: member)
    create(:group_membership, group: group, user: third_member)
  end

  describe "#call" do
    context "with equal split" do
      it "splits the amount across all group members" do
        splits = described_class.new(group: group, total_amount: "10.00", split_type: "equal").call

        expect(splits.size).to eq(3)
        expect(splits.sum { |split| split[:amount] }).to eq(BigDecimal("10.00"))
      end
    end

    context "with custom split" do
      it "returns the exact custom split" do
        splits = described_class.new(
          group: group,
          total_amount: "10.00",
          split_type: "custom",
          custom_splits: [
            { user_id: creator.id, amount: "3.00" },
            { user_id: member.id, amount: "7.00" }
          ]
        ).call

        expect(splits).to match_array(
          [
            { user_id: creator.id, amount: BigDecimal("3.00") },
            { user_id: member.id, amount: BigDecimal("7.00") }
          ]
        )
      end

      it "raises when custom split total does not match expense amount" do
        expect do
          described_class.new(
            group: group,
            total_amount: "10.00",
            split_type: "custom",
            custom_splits: [
              { user_id: creator.id, amount: "5.00" },
              { user_id: member.id, amount: "1.00" }
            ]
          ).call
        end.to raise_error(ValidationError, "Custom splits total must equal expense amount")
      end
    end
  end
end
