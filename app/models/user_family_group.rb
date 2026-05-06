class UserFamilyGroup < ApplicationRecord
  belongs_to :user
  belongs_to :family_group

  # validate: true により、enum に存在しない値の代入で ArgumentError を発生させる代わりに
  # validation エラーとして扱う（params 経由で来る不正値で 500 になるのを防ぐ）。
  enum :role, { owner: 0, member: 1 }, validate: true  # defaultはmember

  validates :user_id, uniqueness: { message: "は1つの家族グループにしか所属できません" }

  # 最後のオーナーが member に降格されないようにする（操作後に owner が 0 人になる変更を弾く）。
  validate :must_keep_at_least_one_owner_after_demotion, on: :update

  # 最後のオーナーが脱退できないようにする。
  before_destroy :ensure_at_least_one_owner_remains_after_leave

  private

  def must_keep_at_least_one_owner_after_demotion
    return unless role_changed? && role_was == "owner"
    return if other_owners_exist?

    errors.add(:role, "を変更するには、別のメンバーをオーナーに指定してください")
  end

  def ensure_at_least_one_owner_remains_after_leave
    return unless owner?
    return if other_owners_exist?

    errors.add(:base, "最後のオーナーが脱退するには、別のメンバーをオーナーに指定してください")
    throw :abort
  end

  def other_owners_exist?
    family_group.user_family_groups.where(role: :owner).where.not(id: id).exists?
  end
end
