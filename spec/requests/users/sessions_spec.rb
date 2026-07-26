require "rails_helper"

RSpec.describe "Users::Sessions", type: :request do
  let(:user) { create(:user, password: "password123") }

  describe "GET /users/sign_in (new)" do
    it "200" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users/sign_in (create)" do
    it "正しい資格情報でログインし、authenticated_root へリダイレクト" do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      expect(response).to redirect_to(authenticated_root_path)
    end

    it "誤ったパスワードはログインできない" do
      post user_session_path, params: { user: { email: user.email, password: "wrong" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "保護ページ閲覧後のログインは保存先(stored_location)へ戻る" do
      get mypage_path # 未ログイン → サインインへ誘導され、遷移先が保存される
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
      expect(response).to redirect_to(mypage_path)
    end
  end

  describe "DELETE /users/sign_out (destroy)" do
    it "ログアウト後 root へリダイレクト" do
      sign_in user
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
