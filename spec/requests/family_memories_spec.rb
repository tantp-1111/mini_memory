require "rails_helper"

RSpec.describe "FamilyMemories", type: :request do
  let(:group)    { create(:family_group) }
  let(:poster)   { create(:user) } # 投稿者（グループメンバー）
  let(:viewer)   { create(:user) } # 同じグループの閲覧者
  let(:outsider) { create(:user) } # 別グループ未所属の第三者

  before do
    create(:user_family_group, user: poster, family_group: group, role: :owner)
    create(:user_family_group, user: viewer, family_group: group, role: :member)
  end

  describe "GET /family_memories (index)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        get family_memories_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "ログイン済みユーザーは 200" do
      sign_in viewer
      get family_memories_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /family_memories/:uuid (show)" do
    let(:unlisted_memory)  { create(:memory, user: poster, visibility: :unlisted) }
    let(:published_memory) { create(:memory, user: poster, visibility: :published) }
    let(:private_memory)   { create(:memory, user: poster, visibility: :private_only) }

    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        get family_memory_path(unlisted_memory)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "同じグループのメンバー" do
      before { sign_in viewer }

      it "unlisted な家族の投稿は 200" do
        get family_memory_path(unlisted_memory)
        expect(response).to have_http_status(:ok)
      end

      it "published な家族の投稿は 200" do
        get family_memory_path(published_memory)
        expect(response).to have_http_status(:ok)
      end

      it "private_only な投稿は認可エラーで root へ" do
        get family_memory_path(private_memory)
        expect(response).to redirect_to(root_path)
      end
    end

    it "別グループの第三者は unlisted でも認可エラーで root へ" do
      sign_in outsider
      get family_memory_path(unlisted_memory)
      expect(response).to redirect_to(root_path)
    end

    it "存在しない uuid は 404" do
      sign_in viewer
      get family_memory_path("nonexistent-uuid")
      expect(response).to have_http_status(:not_found)
    end
  end
end
