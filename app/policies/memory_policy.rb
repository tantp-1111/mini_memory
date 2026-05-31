# Memory に対する認可ルール。
# 文脈ごとに使うべきメソッド/スコープが異なる:
# - 投稿者本人の編集動線(/memories/:uuid) → show? / update? / destroy?
# - 家族メンバー閲覧(/family_memories/:uuid) → family_show? + FamilyFeedScope
# - 公開掲示板(/public_memories/:uuid) は Memory.publicly_available を直接使い Pundit を経由しない
class MemoryPolicy < ApplicationPolicy
  def index?   = true
  def show?    = owner?
  def create?  = user.present?
  def update?  = owner?
  def destroy? = owner?
  # /family_memories/:uuid 用。private_only は対象外。
  # owner ケースも family_member_of_owner? に委ねることで、家族グループ未所属の
  # 本人が一覧 (FamilyFeedScope = 0 件) と詳細で挙動が食い違うのを防ぐ。
  def family_show?
    return false if user.nil?
    return false unless record.unlisted? || record.published?
    family_member_of_owner?
  end
  # 公開投稿に対してリアクション可能か。判定ロジックは Memory#reactable_by? に集約。
  def react?   = record.published? && record.reactable_by?(user)

  # /memories index 用 - 自分の投稿のみ。
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      scope.where(user: user)
    end
  end

  # /family_memories index 用 - 家族メンバー横断 (unlisted + published)。
  # コントローラ側で policy_scope(Memory, policy_scope_class: MemoryPolicy::FamilyFeedScope) と明示。
  # 家族グループ未所属の場合は user.family_groups が空 → subquery が空 → 結果 0 件。
  class FamilyFeedScope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      family_user_ids = UserFamilyGroup
                          .where(family_group_id: user.family_groups.select(:id))
                          .select(:user_id)
      scope.where(user_id: family_user_ids, visibility: [ :unlisted, :published ])
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
