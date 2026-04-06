FactoryBot.define do
  factory :expense_split do
    expense
    user
    amount { "15.00" }
  end
end
