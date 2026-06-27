require "rails_helper"

RSpec.describe "Reactions", type: :request do
  # owner   … 投稿者（自分の投稿にはリアクション不可）
  # reactor … リアクションする他人
  let(:owner)   { create(:user) }
  let(:reactor) { create(:user) }
  # 公開掲示板に出ている他人の投稿
  let(:memory)  { create(:memory, user: owner, visibility: :published) }

  describe "POST /public_memories/:public_memory_uuid/reactions (create)" do
    let(:params) { { reaction_type: "heart" } }

    context "未ログイン" do
      it "サインイン画面にリダイレクト + Reaction は作成されない" do
        expect {
          post public_memory_reactions_path(memory), params: params
        }.not_to change(Reaction, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み・他人の公開投稿" do
      before { sign_in reactor }

      it "Reaction が 1 件作成される（html はリダイレクト）" do
        expect {
          post public_memory_reactions_path(memory), params: params
        }.to change(Reaction, :count).by(1)
        expect(response).to redirect_to(public_memory_path(memory))
      end

      it "turbo_stream でも作成される" do
        expect {
          post public_memory_reactions_path(memory), params: params, as: :turbo_stream
        }.to change(Reaction, :count).by(1)
        expect(response).to have_http_status(:ok)
      end

      it "同じリアクションを重複して押しても増えない（uniqueness）" do
        create(:reaction, user: reactor, memory: memory, reaction_type: :heart)
        expect {
          post public_memory_reactions_path(memory), params: params
        }.not_to change(Reaction, :count)
      end

      it "無効な reaction_type は作成されず掲示板へリダイレクト" do
        expect {
          post public_memory_reactions_path(memory), params: { reaction_type: "invalid_type" }
        }.not_to change(Reaction, :count)
        expect(response).to redirect_to(public_memory_path(memory))
      end
    end

    context "自分の投稿にはリアクションできない" do
      before { sign_in owner }

      it "認可エラーで作成されず root へリダイレクト" do
        expect {
          post public_memory_reactions_path(memory), params: params
        }.not_to change(Reaction, :count)
        expect(response).to redirect_to(root_path)
      end
    end

    context "非公開(private_only)投稿にはリアクションできない" do
      let(:private_memory) { create(:memory, user: owner, visibility: :private_only) }
      before { sign_in reactor }

      it "認可エラーで作成されず root へリダイレクト" do
        expect {
          post public_memory_reactions_path(private_memory), params: params
        }.not_to change(Reaction, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /public_memories/:public_memory_uuid/reactions/:reaction_type (destroy)" do
    context "未ログイン" do
      before { create(:reaction, user: reactor, memory: memory, reaction_type: :heart) }

      it "サインイン画面にリダイレクト" do
        delete public_memory_reaction_path(memory, "heart")
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み・自分のリアクション" do
      before do
        sign_in reactor
        create(:reaction, user: reactor, memory: memory, reaction_type: :heart)
      end

      it "Reaction が 1 件削除される" do
        expect {
          delete public_memory_reaction_path(memory, "heart")
        }.to change(Reaction, :count).by(-1)
        expect(response).to redirect_to(public_memory_path(memory))
      end
    end
  end
end
