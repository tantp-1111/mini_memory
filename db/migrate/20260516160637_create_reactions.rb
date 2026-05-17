class CreateReactions < ActiveRecord::Migration[7.2]
  def change
    create_table :reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :memory, null: false, foreign_key: true
      t.integer :reaction_type

      t.timestamps
    end

    add_index :reactions, [ :user_id, :memory_id, :reaction_type ], unique: true
  end
end
