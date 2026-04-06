require "rails_helper"

RSpec.describe Group, type: :model do
  let(:group) { create(:group, creator: creator) }
  let(:creator) { create(:user) }
  let(:member) { create(:user) }

  describe "#member?" do
    it "returns true for an existing membership" do
      create(:group_membership, group: group, user: member)

      expect(group.member?(member)).to be(true)
    end

    it "returns false for non-members" do
      expect(group.member?(member)).to be(false)
    end
  end
end
