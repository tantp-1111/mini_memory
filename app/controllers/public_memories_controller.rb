class PublicMemoriesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :memory_not_found

  # publishedのみ取得
  def index
    @public_memories = Memory.published.with_attached_image.order(created_at: :desc)
  end

  def show
    @memory = Memory.published.find_by!(uuid: params[:id])
    # published以外はActiveRecord::RecordNotFoundが発生し、
    # memory_not_foundメソッドで処理される
  end

  private

  def memory_not_found
    redirect_to public_memories_path, alert: "投稿が見つかりませんでした"
  end
end
