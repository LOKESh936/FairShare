class CreateSettlements < ActiveRecord::Migration[7.1]
  def change
    create_table :settlements do |t|
      t.references :group, null: false, foreign_key: true
      t.references :from_user, null: false, foreign_key: { to_table: :users }
      t.references :to_user, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 12, scale: 2, null: false

      t.timestamps
    end
  end
end
