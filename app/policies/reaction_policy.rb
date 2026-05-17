# Reaction の認可ルール。
# 作成可否は MemoryPolicy#react? が担当（リソースの主は Memory のため）。
# 当ポリシーは「個別のリアクションを削除できるか」を判定する。
class ReactionPolicy < ApplicationPolicy
  def destroy?
    return false if user.nil?
    record.user_id == user.id
  end
end
