class MemoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memory, only: %i[show edit update destroy]
  # index は policy_scope のみで authorize を呼ばないため verify_authorized を除外。
  skip_after_action :verify_authorized, only: :index

  def index
    @my_memories = policy_scope(Memory).with_attached_image.order(created_at: :desc)
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
      # multipart で生ファイルが送られた場合のみ webp 変換 + attach し直す。
      # direct_upload や hidden_field 経由で signed_id 文字列が来た場合は、
      # build(memory_params) の時点で既に attach 済みなので追加処理は不要。
      attach_processed_image!(@memory) if params[:memory][:image].is_a?(ActionDispatch::Http::UploadedFile)

      if @memory.save
        flash[:success] = t("defaults.flash_message.created", model: Memory.model_name.human)
        redirect_to memories_path
      else
        @available_children = policy_scope(Child).order(:birthday)
        flash.now[:error] = t("defaults.flash_message.not_created", model: Memory.model_name.human)
        render :new, status: :unprocessable_entity
      end

    # モジュールで設定したエラーのキャッチ
    rescue ImageProcessable::ImageProcessingError => e
      @available_children = policy_scope(Child).order(:birthday)
      flash.now[:error] = e.message
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_children = policy_scope(Child).order(:birthday)
  end

  def update
    begin
      @memory.assign_attributes(memory_params.except(:image))
      # multipart で生ファイルが送られた場合のみ webp 変換 + attach し直す。
      # direct_upload や hidden_field 経由で signed_id 文字列が来た場合は、
      # assign_attributes 側ですでに attach 済みのため追加処理は不要。
      if params[:memory][:image].is_a?(ActionDispatch::Http::UploadedFile)
        attach_processed_image!(@memory)
      elsif params[:memory][:image].is_a?(String) && params[:memory][:image].present?
        # signed_id 文字列を memory に attach(assign_attributes は image を except していたため)
        @memory.image = params[:memory][:image]
      end

      if @memory.save
        flash[:success] = t("defaults.flash_message.updated", model: Memory.model_name.human)
        redirect_to memories_path
      else
        @available_children = policy_scope(Child).order(:birthday)
        flash.now[:error] = t("defaults.flash_message.not_updated", model: Memory.model_name.human)
        render :edit, status: :unprocessable_entity
      end

    # モジュールで設定したエラーのキャッチ
    rescue ImageProcessable::ImageProcessingError => e
      @available_children = policy_scope(Child).order(:birthday)
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
    params.require(:memory).permit(:title, :description, :memory_date, :visibility, :image, :tag_list_input, child_ids: []).tap do |whitelisted|
      # 空文字列を除外
      whitelisted[:child_ids]&.reject!(&:blank?)
    end
  end

  # webp 変換した画像を blob として即時アップロードして memory に attach する。
  # blob を即 persist + storage upload しておくことで、バリデーション失敗で
  # render :new/:edit になった場合もプレビューが再表示できる。
  #
  # ActiveStorage の create_and_upload! が投げる例外は ImageProcessable::ImageProcessingError
  # にラップして、create/update 側の rescue に接続する。
  def attach_processed_image!(memory)
    processed = ImageProcessable.process_and_transform_image(params[:memory][:image], 854)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: processed.tempfile,
      filename: processed.original_filename,
      content_type: processed.content_type
    )
    memory.image.attach(blob)
  rescue ActiveStorage::Error, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Image upload error: #{e.message}"
    raise ImageProcessable::ImageProcessingError, "画像の保存中にエラーが発生しました: #{e.message}"
  end
end
