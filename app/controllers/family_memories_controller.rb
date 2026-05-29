class FamilyMemoriesController < ApplicationController
  before_action :authenticate_user!
  # policy_scope のみで authorize を呼ばないため verify_authorized を除外。
  skip_after_action :verify_authorized

  def index
    @q = policy_scope(Memory, policy_scope_class: FamilyFeedMemoryPolicy::Scope).ransack(params[:q])
    @memories = @q.result(distinct: true)
                  .with_attached_image
                  .includes(:user)
                  .order(created_at: :desc)
    @has_family_group = current_user.family_groups.exists?
  end
end
