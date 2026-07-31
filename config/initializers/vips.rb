# 信頼できない画像入力に対して、libvips の「untrusted」ローダー
# (SVG/PDF 等の外部参照を伴う危険なローダー) を無効化する。
# Active Storage + libvips 経由の任意ファイル読み取り/RCE (CVE-2026-66066) への
# 多層防御。本アプリは png/jpg/jpeg/webp のみ扱うため副作用はない。
require "vips"
Vips.block_untrusted(true)
