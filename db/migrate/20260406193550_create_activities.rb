class CreateActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :activities do |t|
      t.references :group, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action_type, null: false
      t.references :trackable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :activities, [ :group_id, :created_at ]
  end
end
