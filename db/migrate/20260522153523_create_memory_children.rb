class CreateMemoryChildren < ActiveRecord::Migration[7.2]
  def change
    create_table :memory_children do |t|
      t.references :memory, null: false, foreign_key: true
      t.references :child,  null: false, foreign_key: true
      t.timestamps
      t.index [ :memory_id, :child_id ], unique: true
    end
  end
end
