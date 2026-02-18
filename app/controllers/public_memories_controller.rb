class PublicMemoriesController < ApplicationController
  # 認証不要 - 公開された思い出は誰でも見れるようにするため
  skip_before_action :authenticate_user!
  # 例外処理 - 公開されていない思い出にアクセスした場合は一覧ページにリダイレクトしてエラーメッセージを表示
  rescue_from ActiveRecord::RecordNotFound, with: :memory_not_found

  # publishedのみ取得
  def index
    @public_memories = Memory.publicly_available.with_attached_image.order(created_at: :desc)
  end

  def show
    @memory = Memory.publicly_available.find_by!(uuid: params[:uuid])
    # published以外はActiveRecord::RecordNotFoundが発生し、
    # memory_not_foundメソッドで処理される
  end

  private

  def memory_not_found
    redirect_to public_memories_path, alert: "投稿が見つかりませんでした"
  end
end
