class Memory < ApplicationRecord
  # バリデーション
  validates :title, presence: true, length: { maximum: 255 }
  validates :description, presence: true, length: { maximum: 65_535 }
  validates :memory_date, presence: true
  validates :image, presence: true

  # アソシエーション
  belongs_to :user
  has_one_attached :image
  has_many :reactions, dependent: :destroy
  has_many :memory_children, dependent: :destroy
  has_many :children, through: :memory_children
  has_many :memory_tags, dependent: :destroy
  has_many :tags, through: :memory_tags

  # imageカスタムバリデーション
  validate :image_content_type
  validate :image_size
  # 紐付け可能なこどもは投稿者の家族グループに属するものに限定
  validate :children_must_belong_to_user_family_group

  # フォームのカンマ区切り入力を受け取るための仮想 attribute
  attr_accessor :tag_list_input

  # メモリーが保存された後に、tag_list_input をもとに tags 関連を同期する
  after_save :sync_tags_from_input

  TAG_LIMIT = 10
  TAG_MAX_LENGTH = 30

  # enum公開範囲定義
  enum :visibility, {
    private_only: 0,   # 本人のみ閲覧可能
    unlisted: 1,       # 家族グループメンバーのみ閲覧可能
    published: 2       # 掲示板にて誰でも閲覧可能、非公開URLを知っている人も閲覧可能
  }

  # 公開投稿のみを取得するスコープ
  scope :publicly_available, -> { where(visibility: :published) }

  # Ransack で検索可能なカラムの allow-list。明示しないカラムは検索クエリから弾かれる。
  # 認可で守るべき情報(user_id, visibility 等)を意図せず晒さないため最小権限で運用する。
  def self.ransackable_attributes(_auth_object = nil)
    %w[title description]
  end

  # tags 経由のタグクリック絞り込みを許可。children は次回 PR で追加予定。
  def self.ransackable_associations(_auth_object = nil)
    %w[tags]
  end

  # 定数
  # 画像はwebpで保存される - 注意!
  ACCEPT_CONTENT_TYPE = [ "image/png", "image/jpg", "image/jpeg", "image/webp" ].freeze
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

  # user がこの memory の投稿者か（MemoryPolicy#owner? もこれを利用）
  def owned_by?(user)
    return false if user.nil?
    user_id == user.id
  end

  # reaction関係
  # リアクションの種類ごとの数を取得するメソッド
  def reaction_count(reaction_type)
    reactions.where(reaction_type: reaction_type).count
  end

  # 特定のユーザーがそのリアクションを押しているか確認
  def reacted_by?(user, reaction_type)
    reactions.exists?(user: user, reaction_type: reaction_type)
  end

  # user がこの memory にリアクション可能か（ログイン中 & 自分の投稿ではない）
  def reactable_by?(user)
    return false if user.nil?
    !owned_by?(user)
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

  # 紐付け対象のこどもは投稿者の家族グループ内に限る（フォーム改ざん防御）
  def children_must_belong_to_user_family_group
    return if children.empty?
    return if user.nil?

    user_group_ids = user.user_family_groups.pluck(:family_group_id)
    invalid = children.reject { |c| user_group_ids.include?(c.family_group_id) }
    return if invalid.empty?

    errors.add(:children, :not_in_user_family_group)
  end

  # カンマ区切り入力をパースしてタグを同期する（after_save で呼ばれる）。
  # - 前後 strip + 重複除外
  # - 最大 TAG_LIMIT(10) 件まで採用
  # - TAG_MAX_LENGTH(30) 字超のタグは静かに無視（投稿そのものを失敗させない）
  def sync_tags_from_input
    return unless @tag_list_input.is_a?(String)
    return if user.nil?

    names = @tag_list_input.split(",").map(&:strip).reject(&:blank?).uniq
    names = names.first(TAG_LIMIT)
    names = names.reject { |n| n.length > TAG_MAX_LENGTH }

    new_tags = names.map { |name| user.tags.find_or_create_by!(name: name) }
    self.tags = new_tags
  end
end
