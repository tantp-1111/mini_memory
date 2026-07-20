require "rails_helper"

RSpec.describe "Users::Registrations", type: :request do
  describe "GET /users/sign_up (new)" do
    it "200" do
      get new_user_registration_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users (create)" do
    it "name 付きで登録でき、authenticated_root へリダイレクト" do
      expect {
        post user_registration_path, params: {
          user: { name: "新規ユーザー", email: "new@example.com",
                  password: "password123", password_confirmation: "password123" }
        }
      }.to change(User, :count).by(1)
      expect(User.last.name).to eq("新規ユーザー")
      expect(response).to redirect_to(authenticated_root_path)
    end

    it "不正な入力では登録されない" do
      expect {
        post user_registration_path, params: {
          user: { name: "", email: "bad", password: "x", password_confirmation: "y" }
        }
      }.not_to change(User, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /users (update)" do
    let(:user) { create(:user, password: "password123") }
    before { sign_in user }

    it "パスワードなしで name を更新でき、mypage へリダイレクト" do
      patch user_registration_path, params: { user: { name: "更新後の名前" } }
      expect(user.reload.name).to eq("更新後の名前")
      expect(response).to redirect_to(mypage_path)
    end
  end
end
