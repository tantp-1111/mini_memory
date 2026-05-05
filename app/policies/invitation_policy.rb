# Invitation（家族グループへの招待リンク）に対する認可ルール。
# 招待リンクの発行・閲覧・削除はグループの owner のみ可能。
# 招待トークン経由の受諾フローは未認証ユーザーでも辿れるが、その経路は
# Pundit を経由せず、コントローラ側で token 検証で代替する想定。
class InvitationPolicy < ApplicationPolicy
  def index?   = group_owner?
  def show?    = group_owner?
  def create?  = group_owner?
  def destroy? = group_owner?

  # 自分が owner であるグループの招待のみ可視。
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      owned_group_ids = UserFamilyGroup.where(user_id: user.id, role: :owner).select(:family_group_id)
      scope.where(family_group_id: owned_group_ids)
    end
  end

  private

  def group_owner?
    return false if user.nil?
    UserFamilyGroup.exists?(family_group_id: record.family_group_id, user_id: user.id, role: :owner)
  end
end
