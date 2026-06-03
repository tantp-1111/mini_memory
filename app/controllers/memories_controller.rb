class MemoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memory, only: %i[show edit update destroy]
  # index は policy_scope のみで authorize を呼ばないため verify_authorized を除外。
  skip_after_action :verify_authorized, only: :index

  def index
    @q = policy_scope(Memory).ransack(params[:q])
    @my_memories = @q.result(distinct: true).with_attached_image.order(created_at: :desc)
    @available_children = policy_scope(Child).order(:birthday)
  end

  def new
    @memory = Memory.new
    authorize @memory
    @available_children = policy_scope(Child).order(:birthday)
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
        render_form_failure(:new)
      end

    # モジュールで設定したエラーのキャッチ
    rescue ImageProcessable::ImageProcessingError => e
      flash.now[:error] = e.message
      render_form_failure(:new)
    end
  end

  def edit
    @available_children = policy_scope(Child).order(:birthday)
  end

  def update
    begin
      @memory.assign_attributes(memory_params.except(:image))
      if params[:memory][:image].present?
        @memory.image = ImageProcessable.process_and_transform_image(params[:memory][:image], 854)
      end

      if @memory.save
        flash[:success] = t("defaults.flash_message.updated", model: Memory.model_name.human)
        redirect_to memories_path
      else
        flash.now[:error] = t("defaults.flash_message.not_updated", model: Memory.model_name.human)
        render_form_failure(:edit)
      end

    # モジュールで設定したエラーのキャッチ
    rescue ImageProcessable::ImageProcessingError => e
      flash.now[:error] = e.message
      render_form_failure(:edit)
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
    params.require(:memory).permit(:title, :description, :memory_date, :visibility, :image, :tag_list_input, child_ids: []).tap do |whitelisted|
      # 空文字列を除外
      whitelisted[:child_ids]&.reject!(&:blank?)
    end
  end

  # バリデーション/画像処理失敗時のレスポンス。
  # turbo_stream で error メッセージと flash を差し替えることで form 全体の DOM
  # (ファイル選択状態・プレビュー・テキスト入力値) を保持し、画像再選択を不要にする。
  def render_form_failure(action)
    @available_children = policy_scope(Child).order(:birthday)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("error_explanation_container",
                              partial: "shared/error_messages",
                              locals: { object: @memory }),
          turbo_stream.replace("flash_messages", partial: "shared/flash_message")
        ], status: :unprocessable_entity
      end
      format.html { render action, status: :unprocessable_entity }
    end
  end
end
