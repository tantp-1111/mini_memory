class AddUuidToMemories < ActiveRecord::Migration[7.2]
  def change
    # PostgreSQLのuuid生成機能（pgcrypto）を有効化
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    # memoriesにuuidカラムを追加（レコード作成時に自動生成、nullを許可しない）
    add_column :memories, :uuid, :uuid, default: "gen_random_uuid()", null: false
    add_index :memories, :uuid, unique: true
  end
end
