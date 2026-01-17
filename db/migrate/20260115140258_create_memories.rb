class CreateMemories < ActiveRecord::Migration[7.2]
  def change
    create_table :memories do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.date :memory_date

      t.references :user, foreign_key: true, null: false

      t.integer :visibility, null: false, default: 0
      # private: 0, unlisted: 1, published: 2

      t.timestamps
    end
  end
end
