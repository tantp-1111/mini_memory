require "rails_helper"

# 一時的な確認 spec: 修正後の CI で view レンダリングが通るかを 1 件で確認する。
# 通った後に削除し、本来の memories_spec.rb を別コミットで導入する。
RSpec.describe "View Render Smoke", type: :request do
  it "ログイン済みで GET /memories が view を 5xx 無しで描画できる" do
    user = create(:user)
    sign_in user
    get memories_path
    expect(response.status).to be < 500
  end
end
