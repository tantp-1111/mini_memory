class Memory < ApplicationRecord
  # バリデーション
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 65_535 }
  validates :memory_date, presence: true
  validates :image, presence: true

  # アソシエーション
  belongs_to :user
  has_one_attached :image

  # imageカスタムバリデーション
  validate :image_content_type
  validate :image_size

  # enum公開範囲定義
  enum :visibility, {
    private_only: 0,   # 本人のみ閲覧可能
    # unlisted: 1,  # 家族グループメンバーのみ閲覧可能
    published: 2     # 掲示板にて誰でも閲覧可能、非公開URLを知っている人も閲覧可能
  }

  # 公開投稿のみを取得するスコープ
  scope :publicly_available, -> { where(visibility: :published) }

  # 定数
  ACCEPT_CONTENT_TYPE = [ "image/png", "image/jpg", "image/jpeg" ].freeze
  MAX_IMAGE_SIZE = 10.megabytes

  # enumの選択肢を国際化対応した配列で返すクラスメソッド
  def self.visibility_options_for_select
    Memory.visibilities.keys.map do |key|
      [ I18n.t("enums.memory.visibility.#{key}"), key ]
    end
  end

  # 画像表示用メソッド
  def display_image
    return default_image unless image.attached?
    return default_image unless image.content_type.in?(ACCEPT_CONTENT_TYPE)

    image.variant(resize_to_limit: [ 200, 200 ])
  end

  # URLのパラメータとしてuuidを使用
  def to_param
    uuid
  end

  private

  # アップロード形式のバリデーション
  def image_content_type
    if image.attached? && !image.content_type.in?(ACCEPT_CONTENT_TYPE)
      errors.add(:image, "はJPEG、JPG、PNGのみアップロード可能です")
    end
  end

  # 画像サイズのバリデーション
  def image_size
    if image.attached? && image.blob.byte_size > MAX_IMAGE_SIZE
      errors.add(:image, "は10MB以下にしてください")
    end
  end

  # default画像表示用メソッド
  def default_image
    "memory_placeholder.png"
  end
end
