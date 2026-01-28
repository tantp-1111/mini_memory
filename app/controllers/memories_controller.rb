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

    begin
      if params[:memory][:image].present?
        @memory.image = ImageProcessable.process_and_transform_image(params[:memory][:image], 854)
      end

      if @memory.save
        flash[:success] = t("defaults.flash_message.created", model: Memory.model_name.human)
        redirect_to memories_path
      else
        flash.now[:error] = t("defaults.flash_message.not_created", model: Memory.model_name.human)
        render :new, status: :unprocessable_entity
      end

    # モジュールで設定したエラーのキャッチ
    rescue ImageProcessable::ImageProcessingError => e
      flash.now[:error] = e.message
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @memory = current_user.memories.find(params[:id])
  end

  def update
    @memory = current_user.memories.find(params[:id])

    begin
      # 画像がアップロードされている場合のみ画像処理を実行
      if params[:memory][:image].present?
        @memory.image = ImageProcessable.process_and_transform_image(params[:memory][:image], 854)
      end

      if @memory.save
        flash[:success] = t("defaults.flash_message.updated", model: Memory.model_name.human)
        redirect_to memories_path
      else
        flash.now[:error] = t("defaults.flash_message.not_updated", model: Memory.model_name.human)
        render :edit, status: :unprocessable_entity
      end

    # モジュールで設定したエラーのキャッチ
    rescue ImageProcessable::ImageProcessingError => e
      flash.now[:error] = e.message
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    memory = current_user.memories.find(params[:id])
    memory.destroy!
    redirect_to memories_path, notice: t("defaults.flash_message.deleted", model: Memory.model_name.human)
  end



  def show
    @memory = current_user.memories.find(params[:id])
  end

  private

  def memory_params
    params.require(:memory).permit(:title, :description, :memory_date, :visibility, :image)
  end
end
