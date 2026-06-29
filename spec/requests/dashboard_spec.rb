require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:user) { create(:user) }

  it "ログイン済みユーザーは / で dashboard が 200" do
    sign_in user
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "自分の最近の投稿が表示される" do
    memory = create(:memory, user: user, title: "ダッシュボードに出る投稿")
    sign_in user
    get root_path
    expect(response.body).to include(memory.title)
  end
end
