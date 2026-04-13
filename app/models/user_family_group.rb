class UserFamilyGroup < ApplicationRecord
  brlongs_to :user
  belongs_to :family_group

  enum role: { owner: 0, member: 1 }  # defaultはmember

  validates :max_three_groupa, on: :create

  private

  def max_three_groupa
    if user.user_family_groups.count >= 3
      errors.add(:base, "1人のユーザーは最大3つの家族グループに所属できます")
    end
  end
end
