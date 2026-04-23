class Invitation < ApplicationRecord
  belongs_to :family_group

  before_create :generate_token

  # 招待が期限切れかどうかを判断するメソッド
  def expired?
    expires_at.nil? || expires_at < Time.current
  end

  private

  # 招待トークンを生成し、有効期限を設定
  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
    self.expires_at = 1.days.from_now
  end
end
