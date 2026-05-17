class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :memory

  enum reaction_type: {
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
    if memory.user_id == user_id
      errors.add(:base, "自分の投稿にはリアクションできません")
    end
  end
end
