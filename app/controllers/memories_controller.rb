class MemoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memory, only: %i[show edit update destroy]

  def index
    @my_memories = policy_scope(Memory).with_attached_image.order(created_at: :desc)
  end

  def new
    @memory = Memory.new
    authorize @memory
  end

  def create
    @memory = current_user.memories.build(memory_params)
    authorize @memory

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
  end

  def update
    begin
      @memory.assign_attributes(memory_params.except(:image))
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
    @memory.destroy!
    redirect_to memories_path, notice: t("defaults.flash_message.deleted", model: Memory.model_name.human)
  end

  def show
  end

  private

  def set_memory
    @memory = Memory.find_by!(uuid: params[:uuid])
    authorize @memory
  end

  def memory_params
    params.require(:memory).permit(:title, :description, :memory_date, :visibility, :image)
  end
end
