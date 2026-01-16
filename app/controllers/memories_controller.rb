class MemoriesController < ApplicationController
  def index
    @my_memories = current_user.memories.order(created_at: :desc)
  end
end
