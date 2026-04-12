class CreateUserFamilyGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :user_family_groups do |t|
      t.references :user, null: false, foreign_key: true
      t.references :family_group, null: false, foreign_key: true
      t.integer :role, null: false, default: 1  # 0: owner, 1: member
      t.timestamps
    end
    add_index :user_family_groups, [:user_id, :family_group_id], unique: true
  end
end
