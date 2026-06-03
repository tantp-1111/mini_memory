class Tag < ApplicationRecord
  belongs_to :user
  has_many :memory_tags, dependent: :destroy
  has_many :memories, through: :memory_tags

  validates :name, presence: true,
                   length: { maximum: 30 },
                   uniqueness: { scope: :user_id }

  # Memory#ransack(tags_name_eq: ...) を通すために name のみ allow-list に追加。
  # user_id / id は URL からの偵察に使われる恐れがあるため許可しない。
  def self.ransackable_attributes(_auth_object = nil)
    %w[name]
  end
end
