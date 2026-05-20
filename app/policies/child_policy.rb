class ChildPolicy < ApplicationPolicy
  # 親リソース(FamilyGroup) のメンバー検証は controller の before_action で実施。
  # ChildPolicy では「オーナーだけが書き込み可能」を表現する。
  def index?   = true
  def show?    = true
  def create?  = owner_of_record_group?
  def update?  = owner_of_record_group?
  def destroy? = owner_of_record_group?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if user.nil?
      # 将来「1ユーザー複数グループ」になっても壊れないよう pluck で配列取得
      group_ids = user.user_family_groups.pluck(:family_group_id)
      return scope.none if group_ids.empty?
      scope.where(family_group_id: group_ids)
    end
  end

  private

  def owner_of_record_group?
    return false if user.nil?
    user.user_family_groups.exists?(
      family_group_id: record.family_group_id, role: :owner
    )
  end
end
