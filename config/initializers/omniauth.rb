OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true

# 開発環境でのみCSRF保護を緩和
if Rails.env.development?
  OmniAuth.config.test_mode = false
  OmniAuth.config.logger = Rails.logger
end