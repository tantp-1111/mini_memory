class Api::MemoryGamesController < ApplicationController
  before_action :authenticate_user!

  MINIMUM_CARDS = 2
  MAXIMUM_CARDS = 8

  def show
    # シンプルなJOINでIDのみ取得（with_attached_imageを使わない）
    base_ids = policy_scope(Memory)
                 .joins(:image_attachment)
                 .pluck(:id)

    total = base_ids.count

    if total < MINIMUM_CARDS
      render json: { sufficient: false, needed: MINIMUM_CARDS - total }
      return
    end

    # ランダムに選択
    selected_ids = base_ids.sample(MAXIMUM_CARDS)

    # 選んだIDで画像付きレコードを取得
    selected = policy_scope(Memory)
                 .with_attached_image
                 .where(id: selected_ids)

    cards = selected.map do |memory|
      {
        id:          memory.id,
        uuid:        memory.uuid,
        title:       memory.title,
        description: memory.description,
        memory_date: memory.memory_date&.strftime("%Y年%m月%d日"),
        url:         url_for(memory.image)
      }
    end

    render json: { sufficient: true, cards: cards }
  end
end
