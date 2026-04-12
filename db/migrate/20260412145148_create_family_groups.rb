class CreateFamilyGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :family_groups do |t|
      t.string :name, null: false
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.timestamps
    end
  end
end
