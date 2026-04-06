class CreateExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :expenses do |t|
      t.references :group, null: false, foreign_key: true
      t.references :payer, null: false, foreign_key: { to_table: :users }
      t.string :description, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :split_type, null: false, default: 0

      t.timestamps
    end
  end
end
