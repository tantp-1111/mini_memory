class MemoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    @my_memories = current_user.memories.with_attached_image.order(created_at: :desc)
  end

  def new
    @memory = Memory.new
  end

  def create
    @memory = current_user.memories.build(memory_params)
    if @memory.save
      redirect_to memories_path, notice: t("defaults.flash_message.created", model: Memory.model_name.human)
    else
      flash.now[:error] = t("defaults.flash_message.not_created", model: Memory.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @memory = current_user.memories.find(params[:id])
  end

  private

  def memory_params
    params.require(:memory).permit(:title, :description, :memory_date, :visibility, :image)
  end
end
