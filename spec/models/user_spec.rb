require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.to have_secure_password }

  it "normalizes email before validation" do
    user.email = "  USER@Example.COM "
    user.valid?

    expect(user.email).to eq("user@example.com")
  end
end
