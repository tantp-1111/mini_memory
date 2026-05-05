class DashboardController < ApplicationController
  before_action :authenticate_user!
  # policy_scope のみで authorize を呼ばないため verify_authorized を除外。
  skip_after_action :verify_authorized

  def top
    @recent_memories = policy_scope(Memory).with_attached_image.order(created_at: :desc).limit(6)
  end
end
