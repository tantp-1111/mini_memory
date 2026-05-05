class MemoryGamesController < ApplicationController
  before_action :authenticate_user!
  # ゲーム画面の表示のみで認可対象レコードが無いため verify_authorized を除外。
  skip_after_action :verify_authorized

  def show; end
end
