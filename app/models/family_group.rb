class FamilyGroup < ApplicationRecord
  has_many :user_family_groups, dependent: :destroy
  has_many :users, through: :user_family_groups
  has_many :invitations, dependent: :destroy
  has_many :children, dependent: :destroy

  validates :name, presence: true

  # URLのパラメータとしてuuidを使用
  def to_param
    uuid
  end
end
