require "omniauth-oauth2"
require "json"

module OmniAuth
  module Strategies
    # LINE ログイン用の OmniAuth ストラテジ。
    # 旧 gem "omniauth-line" (0.1.0) が未メンテのため、必要な実装を自前化した。
    # OAuth2 の共通処理（トークン交換・state 検証等）は
    # メンテ継続中の omniauth-oauth2 に委譲し、LINE 固有の差分のみここで定義する。
    class Line < OmniAuth::Strategies::OAuth2
      option :name, "line"
      option :scope, "profile openid"

      option :client_options, {
        site: "https://access.line.me",
        authorize_url: "/oauth2/v2.1/authorize",
        token_url: "/oauth2/v2.1/token"
      }

      # 認可画面は access.line.me、トークン取得・プロフィール取得は api.line.me を使うため
      # コールバック時にホストを切り替える。
      def callback_phase
        options[:client_options][:site] = "https://api.line.me"
        super
      end

      def callback_url
        options[:callback_url] || (full_host + script_name + callback_path)
      end

      uid { raw_info["userId"] }

      info do
        {
          name:        raw_info["displayName"],
          image:       raw_info["pictureUrl"],
          description: raw_info["statusMessage"]
        }
      end

      # PROFILE 権限付きのアクセストークンで LINE プロフィールを取得する。
      def raw_info
        @raw_info ||= JSON.parse(access_token.get("v2/profile").body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end
