# Memory に対する認可ルール。
# 公開済み (published) 投稿は所有者以外も閲覧可能、それ以外は所有者のみ操作可能。
#
# Scope は MemoriesController（認証必須・自分の投稿一覧）向けに「自分の投稿のみ」を返す。
# PublicMemoriesController は公開情報を扱うため Pundit を経由しない設計（Memory.publicly_available を直接使用）。
class MemoryPolicy < ApplicationPolicy
  def index?   = true
  def show?    = record.published? || owner?
  def create?  = user.present?
  def update?  = owner?
  def destroy? = owner?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      scope.where(user: user)
    end
  end

  private

  def owner?
    return false if user.nil?
    record.user_id == user.id
  end
end
