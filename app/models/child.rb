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

  private

  def birthday_not_in_future
    errors.add(:birthday, :in_future) if birthday > Date.current
  end
end
