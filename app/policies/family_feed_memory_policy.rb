# 家族フィード（FamilyMemoriesController#index）専用の Scope を提供する Policy。
#
# MemoryPolicy::Scope は「自分の投稿のみ」を返すため、家族メンバー横断の集合は
# 別 Scope として責務を分離する。コントローラ側で
# policy_scope(Memory, policy_scope_class: FamilyFeedMemoryPolicy::Scope) と
# 明示的に指定して呼び出す。
class FamilyFeedMemoryPolicy < ApplicationPolicy
  # 自分が所属する家族グループのメンバー（自分含む）が投稿した unlisted / published を返す。
  # private_only は所有者本人専用なのでフィードからは除外する。
  # 家族グループ未所属の場合は user.family_groups が空 → 連鎖する subquery が空 → 結果 0 件。
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      family_user_ids = UserFamilyGroup
                          .where(family_group_id: user.family_groups.select(:id))
                          .select(:user_id)
      scope.where(user_id: family_user_ids, visibility: [ :unlisted, :published ])
    end
  end
end
