class Invitation < ApplicationRecord
  belongs_to :family_group

  before_create :generate_token

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(16)
    self.expires_at = 1.days.from_now
  end
end
