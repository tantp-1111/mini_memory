OmniAuth.config.allowed_request_methods = [ :post ]

# 開発環境でのみCSRF保護を緩和
if Rails.env.development?
  OmniAuth.config.allowed_request_methods = [ :post, :get ]
  OmniAuth.config.silence_get_warning = true
  OmniAuth.config.test_mode = false
  OmniAuth.config.logger = Rails.logger
end
