require "rails_helper"

RSpec.describe "Mypages", type: :request do
  let(:user) { create(:user) }

  it "未ログインはサインイン画面へリダイレクト" do
    get mypage_path
    expect(response).to redirect_to(new_user_session_path)
  end

  it "ログイン済みユーザーは 200" do
    sign_in user
    get mypage_path
    expect(response).to have_http_status(:ok)
  end
end
