# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w[ admin.js admin.css ]

# app/assets/stylesheets/ は Tailwind のビルド入力ソース置き場で配信用ではない。
# 含めたままだと dartsass-sprockets が application.tailwind.css を Sass として処理し、
# 展開された Tailwind v4 構文で parse 失敗する (CI で発生)。
Rails.application.config.assets.paths.reject! do |path|
  path.to_s.end_with?("app/assets/stylesheets")
end
