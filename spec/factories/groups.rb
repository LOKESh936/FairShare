FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    association :creator, factory: :user
  end
end
