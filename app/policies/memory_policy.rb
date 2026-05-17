# Memory に対する認可ルール。
# 公開済み (published) 投稿は所有者以外も閲覧可能、それ以外は所有者のみ操作可能。
#
# Scope は MemoriesController（認証必須・自分の投稿一覧）向けに「自分の投稿のみ」を返す。
# PublicMemoriesController は公開情報を扱うため Pundit を経由しない設計（Memory.publicly_available を直接使用）。
class MemoryPolicy < ApplicationPolicy
  def index?   = true
  def show?    = record.published? || owner? || (record.unlisted? && family_member_of_owner?)
  def create?  = user.present?
  def update?  = owner?
  def destroy? = owner?
  # 公開投稿に対してリアクション可能か。判定ロジックは Memory#reactable_by? に集約。
  def react?   = record.reactable_by?(user)

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      scope.where(user: user)
    end
  end

  private

  def owner?
    record.owned_by?(user)
  end

  # current_user の所属家族グループと record.user の所属家族グループに重複があるか。
  # 「1 ユーザー 1 グループ」制約下では、実質「同じ家族グループに属しているか」の判定。
  def family_member_of_owner?
    return false if user.nil?
    user.family_groups.where(id: record.user.family_groups.select(:id)).exists?
  end
end
