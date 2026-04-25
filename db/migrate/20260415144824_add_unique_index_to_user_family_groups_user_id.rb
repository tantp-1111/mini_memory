class AddUniqueIndexToUserFamilyGroupsUserId < ActiveRecord::Migration[7.2]
  def change
    remove_index :user_family_groups, :user_id
    add_index :user_family_groups, :user_id, unique: true
  end
end
