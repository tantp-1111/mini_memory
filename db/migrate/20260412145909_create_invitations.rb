class CreateInvitations < ActiveRecord::Migration[7.2]
  def change
    create_table :invitations do |t|
      t.references :family_group, null: false, foreign_key: true
      t.string "token", null: false
      t.datetime "expires_at", null: false
      t.timestamps
    end
    add_index :invitations, :token, unique: true
  end
end
