class CreateUserFamilyGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :user_family_groups do |t|
      t.bigint "user_id", null: false
      t.bigint "family_group_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "role", default: 4, null: false
      t.boolean "is_admin", default: false, null: false
      t.timestamps
    end
  end
end
