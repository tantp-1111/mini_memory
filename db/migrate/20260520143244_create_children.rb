class CreateChildren < ActiveRecord::Migration[7.2]
  def change
    create_table :children do |t|
      t.uuid :uuid, default: "gen_random_uuid()", null: false
      t.references :family_group, null: false, foreign_key: true
      t.string :name, null: false
      t.date :birthday

      t.timestamps
    end

    add_index :children, :uuid, unique: true
  end
end
