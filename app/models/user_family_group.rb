class UserFamilyGroup < ApplicationRecord
  belongs_to :user
  belongs_to :family_group

  enum role: { owner: 0, member: 1 }  # defaultはmember

  validate :max_one_group, on: :create

  private

  def max_one_group
    if user.user_family_groups.count >= 1
      errors.add(:base, "ユーザーは1つの家族グループにしか所属できません")
    end
  end
end
