class Memory < ApplicationRecord
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 65_535 }

  belongs_to :user

  has_one_attached :image
  validate :image_content_type
  validate :image_size
  validates :image, presence: true

  enum :visibility, {
    private_only: 0,   # 本人のみ閲覧可能
    unlisted: 1,  # 本人、非公開URLを知っている人のみ閲覧可能
    published: 2     # 掲示板にて誰でも閲覧可能、非公開URLを知っている人も閲覧可能
  }

  # enumの選択肢を国際化対応した配列で返すヘルパーメソッド
  def self.visibility_options_for_select
    Memory.visibilities.keys.map do |key|
      [ I18n.t("enums.memory.visibility.#{key}"), key ]
    end
  end

  ACCEPT_CONTENT_TYPE = %w[image/jpeg image/jpg image/png]
  MAX_IMAGE_SIZE = 10.megabytes

  # アップロード形式のバリデーション
  def image_content_type
    if image.attached? && !image.content_type.in?(ACCEPT_CONTENT_TYPE)
      errors.add(:image, "：JPEG,JPG,PNGをアップロードしてください")
    end
  end
  # 画像サイズのバリデーション
  def image_size
    if image.attached? && image.blob.byte_size > MAX_IMAGE_SIZE
      errors.add(:image, "：10MB以下の画像をアップロードしてください")
    end
  end

  # サムネイル表示用メソッド
  def image_as_thumbnail
    return unless image.attached? && image.content_type.in?(ACCEPT_CONTENT_TYPE)
    image.variant(resize_to_limit: [ 200, 200 ])
  end

  # default画像表示用メソッド
  def default_image
    "memory_placeholder.png"
  end

  # 画像表示用メソッド
  def display_image
    image_as_thumbnail || default_image
  end
end
