class DashboardController < ApplicationController
  before_action :authenticate_user!

  def top
    @recent_memories = current_user.memories.with_attached_image.order(created_at: :desc).limit(6)
  end
end
