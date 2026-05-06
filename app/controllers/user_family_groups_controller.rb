class UserFamilyGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_family_group

  # メンバーの役割変更（owner ⇄ member）。
  # family_group 行を pessimistic lock することで、同時に複数の owner を
  # member に降格して owner が 0 人になる race condition を防ぐ。
  def update
    @membership = @family_group.user_family_groups.find(params[:id])
    authorize @membership

    succeeded = false
    ActiveRecord::Base.transaction do
      @family_group.lock!
      succeeded = @membership.update(role: params[:role])
    end

    if succeeded
      redirect_to @family_group, notice: t("mypage.family_group.show.role_updated")
    else
      redirect_to @family_group, alert: @membership.errors.full_messages.to_sentence
    end
  end

  # 自分自身の脱退のみ対象（owner kick は本機能では扱わない）。
  # current_user.user_family_groups で取得することで他人のメンバーシップ削除を弾く。
  # update と同様に family_group 行をロックして同時脱退の race condition を防ぐ。
  def destroy
    @membership = current_user.user_family_groups.find(params[:id])
    authorize @membership

    succeeded = false
    ActiveRecord::Base.transaction do
      @family_group.lock!
      succeeded = @membership.destroy
    end

    if succeeded
      redirect_to mypage_path, notice: t("mypage.family_group.show.left_group")
    else
      redirect_to @family_group, alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  # 非メンバーには 404（存在隠蔽）、メンバー以上には authorize で操作種別を判定する二段防衛。
  def set_family_group
    @family_group = policy_scope(FamilyGroup).find_by!(uuid: params[:family_group_uuid])
  end
end
