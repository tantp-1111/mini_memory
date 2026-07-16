require "rails_helper"

RSpec.describe "PublicMemories", type: :request do
  let(:author) { create(:user) }

  describe "GET /public_memories (index)" do
    it "未ログインでも 200" do
      get public_memories_path
      expect(response).to have_http_status(:ok)
    end

    it "published のみ一覧に表示し、private_only / unlisted は除外する" do
      published = create(:memory, user: author, visibility: :published,    title: "公開された投稿")
      private_o = create(:memory, user: author, visibility: :private_only, title: "非公開の投稿")
      unlisted  = create(:memory, user: author, visibility: :unlisted,     title: "限定公開の投稿")

      get public_memories_path

      expect(response.body).to include(published.title)
      expect(response.body).not_to include(private_o.title)
      expect(response.body).not_to include(unlisted.title)
    end
  end

  describe "GET /public_memories/:uuid (show)" do
    it "published な投稿は未ログインでも 200" do
      memory = create(:memory, user: author, visibility: :published)
      get public_memory_path(memory)
      expect(response).to have_http_status(:ok)
    end

    it "private_only な投稿は一覧へリダイレクト" do
      memory = create(:memory, user: author, visibility: :private_only)
      get public_memory_path(memory)
      expect(response).to redirect_to(public_memories_path)
    end

    it "unlisted な投稿は一覧へリダイレクト" do
      memory = create(:memory, user: author, visibility: :unlisted)
      get public_memory_path(memory)
      expect(response).to redirect_to(public_memories_path)
    end

    it "存在しない uuid は一覧へリダイレクト" do
      get public_memory_path("nonexistent-uuid")
      expect(response).to redirect_to(public_memories_path)
    end
  end
end
