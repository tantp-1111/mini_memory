class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :memory

  enum :reaction_type, {
    thumbs_up: 0,
    clap: 1,
    heart: 2,
    laugh: 3,
    tear_up: 4
  }

  # 同じユーザーが同じ掲示板に同じリアクションを重複して押せないようにする
  validates :user_id, uniqueness: { scope: [ :memory_id, :reaction_type ] }

  # 自分の投稿にはリアクションできないバリデーション
  validate :cannot_react_to_own_memory

  private

  def cannot_react_to_own_memory
    return if memory.nil? || user_id.nil?
    return unless memory.user_id == user_id

    # i18n キー: activerecord.errors.models.reaction.attributes.base.own_post
    errors.add(:base, :own_post)
  end
end
