FactoryBot.define do
  factory :settlement do
    group
    association :from_user, factory: :user
    association :to_user, factory: :user
    amount { "10.00" }
  end
end
