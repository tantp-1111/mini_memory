class MemoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @my_memories = current_user.memories.includes(:user)order(created_at: :desc)
  end
end
