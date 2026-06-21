# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w[ admin.js admin.css ]

# tailwind.css / application.css は @tailwindcss/cli が --minify で既に圧縮済み。
# dartsass-sprockets の Sass compressor が Tailwind v4 構文を parse できず失敗するため
# (x86_64-linux-gnu の CI でのみ顕在化)、Sprockets の CSS 圧縮自体を無効化する。
Rails.application.config.assets.css_compressor = nil
