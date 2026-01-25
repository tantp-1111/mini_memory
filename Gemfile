source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.2"

# Sprockets - アセットパイプラインの管理
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# PostgreSQL - リレーショナルデータベースアダプタ
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Puma - Ruby/Railsアプリケーション用Webサーバー
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# jsbundling-rails - JavaScriptのバンドルとトランスパイル
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Turbo - ページの高速化（SPA風体験を提供）
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Stimulus - 軽量JavaScriptフレームワーク
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# cssbundling-rails - CSSのバンドルと処理
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Jbuilder - JSON APIの構築
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Redis - リアルタイム通信用インメモリデータストア
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Kredis - Redisの高度なデータ型を提供
# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# bcrypt - パスワードのハッシュ化とセキュアなパスワード機能
# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# tzinfo-data - タイムゾーン情報（Windows/JRuby用）
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Bootsnap - ブートタイムの短縮（キャッシング機能）
# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# image_processing - 画像処理とバリアント生成
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Tailwind CSS - ユーティリティファーストなCSSフレームワーク
gem "tailwindcss-rails"

# Devise - 認証ソリューション
gem "devise"
gem "devise-i18n"

# rails-i18n - 多言語対応（日本語含む）
gem "rails-i18n"

group :development, :test do
  # debug - デバッグツール
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Brakeman - セキュリティ脆弱性の静的解析
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # RuboCop Rails Omakase - Railsのコードスタイル統一
  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # web-console - ブラウザ上でのデバッグコンソール
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Capybara - ブラウザ自動テストフレームワーク
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"

  # Selenium WebDriver - ブラウザ自動化ツール
  gem "selenium-webdriver"

  # minitest - テストの安定性向上のためv5に固定
  gem "minitest", "~> 5.25"
end
