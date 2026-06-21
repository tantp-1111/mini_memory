require "rails_helper"

# 診断用 spec: view レンダリング (= application.html.erb の
# stylesheet_link_tag 評価) を伴う最小ケースを 1 件だけ実行する。
# CI で Sass エラーが起きる条件 (= ログイン済み + view 描画) を再現するため。
# 原因特定後にこのファイルは削除する。
RSpec.describe "Debug View Render", type: :request do
  it "ログイン済みで GET /memories が view を描画できる" do
    user = create(:user)
    sign_in user
    get memories_path
    # status 検証はせず、レンダリングが通れば OK とする
    # (Sass エラーが起きていれば 500 になる)
    expect(response.status).to be < 500
  end
end
