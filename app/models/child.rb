class Child < ApplicationRecord
  belongs_to :family_group
  has_many :memory_children, dependent: :destroy
  has_many :memories, through: :memory_children

  validates :name, presence: true, length: { maximum: 30 }
  validate :birthday_not_in_future, if: -> { birthday.present? }

  # URLのパラメータとしてuuidを使用
  def to_param
    uuid
  end

  # Memory#ransack(children_uuid_eq: ...) を通すために uuid のみ allow-list に追加。
  # name は検索バーから逆引き偵察される懸念があるため許可しない。
  # id / family_group_id も同様に許可しない。
  def self.ransackable_attributes(_auth_object = nil)
    %w[uuid]
  end

  private

  def birthday_not_in_future
    errors.add(:birthday, :in_future) if birthday > Date.current
  end
end
