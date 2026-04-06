FactoryBot.define do
  factory :expense do
    group
    association :payer, factory: :user
    description { "Dinner" }
    amount { "45.00" }
    split_type { :equal }
  end
end
