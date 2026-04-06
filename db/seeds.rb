puts "Seeding FairShare demo data..."

Activity.delete_all
Settlement.delete_all
ExpenseSplit.delete_all
Expense.delete_all
GroupMembership.delete_all
Group.delete_all
User.delete_all

alex = User.create!(
  name: "Alex Johnson",
  email: "alex@example.com",
  password: "password123",
  password_confirmation: "password123"
)

sam = User.create!(
  name: "Sam Lee",
  email: "sam@example.com",
  password: "password123",
  password_confirmation: "password123"
)

jordan = User.create!(
  name: "Jordan Patel",
  email: "jordan@example.com",
  password: "password123",
  password_confirmation: "password123"
)

roommates = Group.create!(name: "Roommates", creator: alex)
trip = Group.create!(name: "Trip to NYC", creator: sam)

[
  [ roommates, alex, :admin ],
  [ roommates, sam, :member ],
  [ roommates, jordan, :member ],
  [ trip, sam, :admin ],
  [ trip, alex, :member ],
  [ trip, jordan, :member ]
].each do |group, user, role|
  GroupMembership.create!(group: group, user: user, role: role)
end

ExpenseCreator.new(
  group: roommates,
  creator: alex,
  params: {
    description: "Groceries",
    amount: "96.00",
    payer_id: alex.id,
    split_type: "equal"
  }
).call

ExpenseCreator.new(
  group: roommates,
  creator: sam,
  params: {
    description: "Internet Bill",
    amount: "60.00",
    payer_id: sam.id,
    split_type: "custom",
    custom_splits: [
      { user_id: alex.id, amount: "30.00" },
      { user_id: sam.id, amount: "15.00" },
      { user_id: jordan.id, amount: "15.00" }
    ]
  }
).call

ExpenseCreator.new(
  group: trip,
  creator: sam,
  params: {
    description: "Hotel",
    amount: "300.00",
    payer_id: sam.id,
    split_type: "equal"
  }
).call

ExpenseCreator.new(
  group: trip,
  creator: jordan,
  params: {
    description: "Broadway Tickets",
    amount: "180.00",
    payer_id: jordan.id,
    split_type: "custom",
    custom_splits: [
      { user_id: alex.id, amount: "60.00" },
      { user_id: sam.id, amount: "60.00" },
      { user_id: jordan.id, amount: "60.00" }
    ]
  }
).call

SettlementCreator.new(
  group: roommates,
  actor: jordan,
  to_user_id: alex.id,
  amount: "10.00"
).call

puts "Seed complete!"
