class FamilyMemoriesController < ApplicationController
  before_action :authenticate_user!
  # index は policy_scope のみで authorize を呼ばないため verify_authorized を除外。
  skip_after_action :verify_authorized, only: :index

  def index
    @q = policy_scope(Memory, policy_scope_class: MemoryPolicy::FamilyFeedScope).ransack(params[:q])
    @memories = @q.result(distinct: true)
                  .with_attached_image
                  .includes(:user)
                  .order(created_at: :desc)
    @has_family_group = current_user.family_groups.exists?
  end

  def show
    @memory = Memory.find_by!(uuid: params[:uuid])
    # 家族フィード文脈の認可 (private_only は不可、unlisted/published かつ本人 or 家族メンバー)
    authorize @memory, :family_show?
  end
end
