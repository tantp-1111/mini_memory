require "rails_helper"

RSpec.describe "Api::MemoryGames", type: :request do
  let(:user) { create(:user) }

  describe "GET /api/memory_game (show)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        get api_memory_game_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み" do
      before { sign_in user }

      it "画像付き投稿が 0 件なら sufficient: false と必要枚数を返す" do
        get api_memory_game_path
        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body["sufficient"]).to be(false)
        expect(body["needed"]).to eq(2)
      end

      it "画像付き投稿が 1 件なら sufficient: false（残り1枚）" do
        create(:memory, user: user)
        get api_memory_game_path
        body = response.parsed_body
        expect(body["sufficient"]).to be(false)
        expect(body["needed"]).to eq(1)
      end

      it "画像付き投稿が 2 件以上なら sufficient: true とカードを返す" do
        create_list(:memory, 3, user: user)
        get api_memory_game_path
        body = response.parsed_body
        expect(body["sufficient"]).to be(true)
        expect(body["cards"].size).to eq(3)
        expect(body["cards"].first.keys).to include("id", "uuid", "title", "description", "memory_date", "url")
      end

      it "他人の投稿はカードに含めない（自分の投稿のみ対象）" do
        create_list(:memory, 2, user: user)
        create_list(:memory, 5, user: create(:user)) # 他人の投稿
        get api_memory_game_path
        body = response.parsed_body
        expect(body["cards"].size).to eq(2)
      end
    end
  end
end
