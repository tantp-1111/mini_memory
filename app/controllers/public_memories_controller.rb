class PublicMemoriesController < ApplicationController
  # 認証不要 - 公開された思い出は誰でも見れるようにするため
  skip_before_action :authenticate_user!
  # 公開情報を扱うため Pundit を経由しない設計（Memory.publicly_available を直接使用）。
  skip_after_action :verify_authorized
  # 例外処理 - 公開されていない思い出にアクセスした場合は一覧ページにリダイレクトしてエラーメッセージを表示
  rescue_from ActiveRecord::RecordNotFound, with: :memory_not_found

  # publishedのみ取得
  def index
    @q = Memory.publicly_available.ransack(params[:q])
    @public_memories = @q.result(distinct: true).with_attached_image.includes(:user).order(created_at: :desc)
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
