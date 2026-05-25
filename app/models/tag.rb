class Tag < ApplicationRecord
  belongs_to :user
  has_many :memory_tags, dependent: :destroy
  has_many :memories, through: :memory_tags

  validates :name, presence: true,
                   length: { maximum: 30 },
                   uniqueness: { scope: :user_id }
end
