module ReactionsHelper
  REACTION_EMOJIS = {
    "thumbs_up" => "👍",
    "clap"      => "👏",
    "heart"     => "❤️",
    "laugh"     => "😂",
    "tear_up"  => "🥺"
  }.freeze

  def reaction_emoji(reaction_type)
    REACTION_EMOJIS[reaction_type]
  end

  # 押下済みなら primary、未押下なら outline のスタイルを返す
  def reaction_button_class(reacted)
    "btn btn-sm gap-1 #{reacted ? 'btn-primary' : 'btn-outline'}"
  end

  # ボタンが押せないときの理由（投稿者本人か未ログインかで出し分け）
  def disabled_reaction_title(memory)
    if memory.owned_by?(current_user)
      I18n.t("reactions.disabled_reason.own_post")
    else
      I18n.t("reactions.disabled_reason.not_logged_in")
    end
  end
end
