class Memory < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 65_535 }

  belongs_to :user

  enum :visibility, {
    private_only: 0,   # 本人のみ閲覧可能
    unlisted: 1,  # 本人、非公開URLを知っている人のみ閲覧可能
    published: 2     # 掲示板にて誰でも閲覧可能、非公開URLを知っている人も閲覧可能
  }
end
