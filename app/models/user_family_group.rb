class UserFamilyGroup < ApplicationRecord
  belongs_to :user
  belongs_to :family_group

  enum :role, { owner: 0, member: 1 }  # defaultはmember

  validates :user_id, uniqueness: { message: "は1つの家族グループにしか所属できません" }
end
