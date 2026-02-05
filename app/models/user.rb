class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[line]
  validates :name, presence: true

  has_many :memories, dependent: :destroy

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)

    user.email =
      auth.info.email.presence ||
      user.email.presence ||
      "#{auth.uid}-#{auth.provider}@example.com"

    user.name =
      auth.info.name.presence ||
      user.name.presence ||
      "LINEユーザー"

    user.password ||= Devise.friendly_token[0, 20]

    user.save!
    user
end
end
