class FamilyGroup < ApplicationRecord
  has_many :user_family_groups, dependent: :destroy
  has_many :users, through: :user_family_groups
  has_many :invitations, dependent: :destroy

  validates :name, presence: true
end
