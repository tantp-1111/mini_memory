class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[line]
  validates :name, presence: true

  has_many :memories, dependent: :destroy

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
end
