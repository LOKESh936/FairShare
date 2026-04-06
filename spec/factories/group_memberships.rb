FactoryBot.define do
  factory :group_membership do
    group
    user
    role { :member }
  end
end
