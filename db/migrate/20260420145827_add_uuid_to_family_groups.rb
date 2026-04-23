class AddUuidToFamilyGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :family_groups, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_index :family_groups, :uuid, unique: true
  end
end
