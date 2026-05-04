# FamilyGroup に対する認可ルール。
# 1 ユーザー 1 グループ制約があるため、create? は未所属ユーザーのみ許可する。
class FamilyGroupPolicy < ApplicationPolicy
  def index?   = user.present?
  def show?    = member?
  def create?  = user.present? && user.user_family_groups.empty?
  def update?  = owner?
  def destroy? = owner?

  # 自分が所属しているグループのみ可視。
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      scope.joins(:user_family_groups).where(user_family_groups: { user_id: user.id })
    end
  end

  private

  def member?
    return false if user.nil?
    record.user_family_groups.exists?(user_id: user.id)
  end

  def owner?
    return false if user.nil?
    record.user_family_groups.exists?(user_id: user.id, role: :owner)
  end
end
