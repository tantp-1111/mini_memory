require "omniauth-oauth2"
require "json"

module OmniAuth
  module Strategies
    # OAuth2 の共通処理（トークン交換・state 検証等）は omniauth-oauth2 に委譲し、LINE 固有の差分のみここで定義
    class Line < OmniAuth::Strategies::OAuth2
      option :name, "line"
      option :scope, "profile"

      option :client_options, {
        site: "https://api.line.me",  # ベースURL
        authorize_url: "https://access.line.me/oauth2/v2.1/authorize",  # 認可画面URL（認可だけ別ホストになる）
        token_url: "/oauth2/v2.1/token"  # トークン取得のURL
      }

      # コールバックURLを明示的に指定
      def callback_url
        full_host + script_name + callback_path
      end

      uid { raw_info["userId"] } # LINEの一意ID → アプリのユーザー識別子

      info do
        {
          name:        raw_info["displayName"]
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
