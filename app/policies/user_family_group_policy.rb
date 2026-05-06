# UserFamilyGroup（グループメンバーシップ）に対する認可ルール。
# 招待経由の自己参加 / 自己脱退と、owner による他メンバー管理を許可する。
class UserFamilyGroupPolicy < ApplicationPolicy
  def show?    = same_group_member?
  def create?  = user.present? && record.user_id == user.id
  def update?  = group_owner?
  def destroy? = self_membership? || group_owner?

  # 「自分自身の脱退」の可否（view のボタン表示判定で使用）。
  # destroy? は owner kick も許可する permissive な定義のため、自己脱退の表示判定は分離する。
  def leave? = self_membership?

  # 自分が属するグループのメンバーシップのみ可視。
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      scope.where(family_group_id: user.family_groups.select(:id))
    end
  end

  private

  def same_group_member?
    return false if user.nil?
    user.family_groups.exists?(id: record.family_group_id)
  end

  def self_membership?
    return false if user.nil?
    record.user_id == user.id
  end

  def group_owner?
    return false if user.nil?
    UserFamilyGroup.exists?(family_group_id: record.family_group_id, user_id: user.id, role: :owner)
  end
end
