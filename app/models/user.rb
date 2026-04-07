class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[line]

  # 定数
  ACCEPTED_CONTENT_TYPES = [ "image/png", "image/jpg", "image/jpeg" ].freeze
  MAX_AVATAR_SIZE = 5.megabytes
  AVATAR_SIZES = {
    small: [24, 24],
    medium: [36, 36]
  }.freeze

  # Active Storageのバリデーション
  has_one_attached :avatar

  # アソシエーション
  has_many :memories, dependent: :destroy

  # バリデーション
  validates :name, presence: true
  validate :avatar_content_type
  validate :avatar_size


  # OmniauthでLINEログインしたときに呼ばれるメソッド - 初回登録&二回目以降のログイン両方で使用
  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    if user.new_record?
      user.email =
      auth.info.email.presence ||
      "#{auth.uid}-#{auth.provider}@example.com"

      user.name =
      auth.info.name.presence ||
      "LINEユーザー"

      user.password = Devise.friendly_token[0, 20]

      user.save
    end

    user
  end

  # アバター画像が添付されているかを判定
  def avatar_attached?
    avatar&.attached?
  end

  # アバター画像のURLまたはイニシャルを返す
  def avatar_display_initial
    name&.slice(0, 1) || "?"
  end

  def avatar_small
    avatar.variant(resize_to_fill: AVATAR_SIZES[:small]) if avatar.attached?
  end

  def avatar_medium
    avatar.variant(resize_to_fill: AVATAR_SIZES[:medium]) if avatar.attached?
  end

  private

  # アップロード形式のバリデーション
  def avatar_content_type
    if avatar.attached? && !avatar.content_type.in?(ACCEPTED_CONTENT_TYPES)
      errors.add(:avatar, "はPNG、JPG、JPEG形式のみアップロード可能です")
    end
  end

  # 画像サイズのバリデーション
  def avatar_size
    if avatar.attached? && avatar.blob.byte_size > MAX_AVATAR_SIZE
      errors.add(:avatar, "は5MB以下にしてください")
    end
  end
end
