module ApplicationHelper
  # Flashメッセージの種類に応じたCSSクラスを返す
  def flash_class_for(type)
    case type.to_s
    when "notice"
      "success"
    when "alert"
      "error"
    else
      type.to_s
    end
  end

  def default_meta_tags
    {
      site: "minimemory",
      title: (content_for?(:title) ? content_for(:title) : "捨てられない思い出を記録するアプリ"),
      reverse: true,
      charset: "utf-8",
      description: "minimemoryを使えば、捨てられない小さなモノの大切な思い出を簡単に記録して共有できます。",
      keywords: "思い出,記録,共有,こども,家族",
      canonical: "#{request.base_url}#{request.path}",
      separator: " | ",
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: "website",
        url: "#{request.base_url}#{request.path}",
        image: ogp_image_url,
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image", # Xで表示する場合は大きいカードを使用
        image: ogp_image_url
      }
    }
  end

  def ogp_image_url
    # @memory が未保存(new record)だと signed_id を取得できないため persisted? を必須にする。
    # 例: 投稿バリデーション失敗で render :new された場合、画像 attach 済みでも未保存
    if @memory&.persisted? && @memory.image.attached?
      return rails_blob_url(@memory.image, only_path: false)
    end
    image_url("minimemory_ogp.png")
  end

  # ナビゲーションのアクティブ状態を判定するヘルパーメソッド
  def active_if(controller)
    controller == controller_name ? "dock-active" : ""
  end

  # ミニメモリのリスト関連のアクティブ状態を判定するヘルパーメソッド
  def active_if_memories_list
    action_name.in?(%w[index show edit update destroy]) ? active_if("memories") : ""
  end

  # ミニメモリの投稿関連のアクティブ状態を判定するヘルパーメソッド
  def active_if_memories_new
    action_name.in?(%w[new create]) ? active_if("memories") : ""
  end

  # 新規投稿 FAB の表示可否。memory の投稿フォーム関連アクションでは出さない。
  def show_new_memory_fab?
    !(controller_name == "memories" && action_name.in?(%w[new create edit update]))
  end
end
