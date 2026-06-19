require "devise"

RSpec.configure do |config|
  # Request spec で sign_in / sign_out を使えるようにする。
  # Devise が同梱する Test::IntegrationHelpers を取り込むことで、
  # `sign_in user` 呼び出し後の get/post に対して current_user がセットされる。
  config.include Devise::Test::IntegrationHelpers, type: :request
end
