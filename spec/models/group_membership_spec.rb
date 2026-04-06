require "rails_helper"

RSpec.describe GroupMembership, type: :model do
  subject(:membership) { create(:group_membership, group: group, user: user) }

  let(:group) { create(:group, creator: user) }
  let(:user) { create(:user) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:group_id) }
end
