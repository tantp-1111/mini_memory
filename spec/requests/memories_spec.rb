require "rails_helper"

RSpec.describe "Memories", type: :request do
  # 登場人物
  # - owner   … Memory の投稿者
  # - stranger … 他人（認可拒否の検証用）
  let(:owner)    { create(:user) }
  let(:stranger) { create(:user) }

  # 各テストで使い回す memory（owner の所有、private_only）
  let(:memory) { create(:memory, user: owner, title: "私のおもいで") }

  # フォームから選択された画像を再現するためのアップロードファイル
  let(:image_file) do
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/test_image_200x200.png"),
      "image/png"
    )
  end

  describe "GET /memories (index)" do
    context "未ログイン" do
      it "サインイン画面にリダイレクトする" do
        get memories_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み" do
      before { sign_in owner }
      # 自分の memory と他人の memory を両方作って policy_scope の絞り込みを検証する
      let!(:my_memory)     { create(:memory, user: owner,    title: "私の宝物のタイトル") }
      let!(:others_memory) { create(:memory, user: stranger, title: "他人の宝物のタイトル") }

      it "200 を返す" do
        get memories_path
        expect(response).to have_http_status(:ok)
      end

      it "自分の memory のタイトルが含まれる" do
        get memories_path
        expect(response.body).to include("私の宝物のタイトル")
      end

      it "他人の memory のタイトルは含まれない（policy_scope の絞り込み）" do
        get memories_path
        expect(response.body).not_to include("他人の宝物のタイトル")
      end
    end
  end

  describe "GET /memories/:uuid (show)" do
    context "未ログイン" do
      it "サインイン画面にリダイレクトする" do
        get memory_path(uuid: memory.uuid)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "投稿者本人" do
      before { sign_in owner }

      it "200 を返す" do
        get memory_path(uuid: memory.uuid)
        expect(response).to have_http_status(:ok)
      end

      it "memory のタイトルが含まれる" do
        get memory_path(uuid: memory.uuid)
        expect(response.body).to include(memory.title)
      end
    end

    context "他人" do
      before { sign_in stranger }

      it "認可エラーで root へリダイレクトされる" do
        get memory_path(uuid: memory.uuid)
        expect(response).to redirect_to(root_path)
      end

      it "flash[:alert] が立つ" do
        get memory_path(uuid: memory.uuid)
        expect(flash[:alert]).to be_present
      end
    end

    context "存在しない uuid" do
      before { sign_in owner }

      # test 環境では show_exceptions = :rescuable のため、
      # ActiveRecord::RecordNotFound はミドルウェアで rescue され 404 が返る
      it "404 (not_found) を返す" do
        get memory_path(uuid: "nonexistent-uuid")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /memories/new" do
    context "未ログイン" do
      it "サインイン画面にリダイレクトする" do
        get new_memory_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み" do
      before { sign_in owner }

      it "200 を返す" do
        get new_memory_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /memories (create)" do
    let(:valid_params) do
      {
        memory: {
          title:        "新しいおもいで",
          description:  "テストの説明文",
          memory_date:  Date.current,
          visibility:   "private_only",
          image:        image_file
        }
      }
    end

    context "未ログイン" do
      it "サインイン画面にリダイレクトする + Memory は作成されない" do
        expect {
          post memories_path, params: valid_params
        }.not_to change(Memory, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "ログイン済み・正常系" do
      before { sign_in owner }

      it "Memory が 1 件作成される" do
        expect {
          post memories_path, params: valid_params
        }.to change(Memory, :count).by(1)
      end

      it "memories_path にリダイレクトされる" do
        post memories_path, params: valid_params
        expect(response).to redirect_to(memories_path)
      end

      it "flash[:success] が立つ" do
        post memories_path, params: valid_params
        expect(flash[:success]).to be_present
      end

      it "作成された Memory は current_user の所有になる" do
        post memories_path, params: valid_params
        expect(Memory.last.user).to eq(owner)
      end
    end

    context "ログイン済み・バリデーションエラー" do
      before { sign_in owner }
      let(:invalid_params) do
        valid_params.deep_dup.tap { |p| p[:memory][:title] = "" }
      end

      it "Memory は作成されない" do
        expect {
          post memories_path, params: invalid_params
        }.not_to change(Memory, :count)
      end

      it "422 (unprocessable_entity) を返す" do
        post memories_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /memories/:uuid/edit" do
    context "未ログイン" do
      it "サインイン画面にリダイレクトする" do
        get edit_memory_path(uuid: memory.uuid)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "投稿者本人" do
      before { sign_in owner }

      it "200 を返す" do
        get edit_memory_path(uuid: memory.uuid)
        expect(response).to have_http_status(:ok)
      end
    end

    context "他人" do
      before { sign_in stranger }

      it "認可エラーで root へリダイレクトされる" do
        get edit_memory_path(uuid: memory.uuid)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /memories/:uuid (update)" do
    let(:update_params) do
      {
        memory: {
          title:        "更新後タイトル",
          description:  memory.description,
          memory_date:  memory.memory_date,
          visibility:   memory.visibility
        }
      }
    end

    context "未ログイン" do
      it "サインイン画面にリダイレクトする + タイトルは更新されない" do
        original_title = memory.title
        patch memory_path(uuid: memory.uuid), params: update_params
        expect(response).to redirect_to(new_user_session_path)
        expect(memory.reload.title).to eq(original_title)
      end
    end

    context "投稿者本人・正常系" do
      before { sign_in owner }

      it "タイトルが更新される" do
        patch memory_path(uuid: memory.uuid), params: update_params
        expect(memory.reload.title).to eq("更新後タイトル")
      end

      it "memories_path にリダイレクトされる" do
        patch memory_path(uuid: memory.uuid), params: update_params
        expect(response).to redirect_to(memories_path)
      end

      it "flash[:success] が立つ" do
        patch memory_path(uuid: memory.uuid), params: update_params
        expect(flash[:success]).to be_present
      end
    end

    context "投稿者本人・バリデーションエラー" do
      before { sign_in owner }
      let(:invalid_params) do
        update_params.deep_dup.tap { |p| p[:memory][:title] = "" }
      end

      it "422 を返す + タイトルは更新されない" do
        original_title = memory.title
        patch memory_path(uuid: memory.uuid), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(memory.reload.title).to eq(original_title)
      end
    end

    context "他人" do
      before { sign_in stranger }

      it "認可エラーで root へリダイレクト + タイトルは更新されない" do
        original_title = memory.title
        patch memory_path(uuid: memory.uuid), params: update_params
        expect(response).to redirect_to(root_path)
        expect(memory.reload.title).to eq(original_title)
      end
    end
  end

  describe "DELETE /memories/:uuid (destroy)" do
    # 削除系は memory を let! で確実に DB に存在させてから検証する
    let!(:target) { create(:memory, user: owner) }

    context "未ログイン" do
      it "サインイン画面にリダイレクト + Memory は削除されない" do
        expect {
          delete memory_path(uuid: target.uuid)
        }.not_to change(Memory, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "投稿者本人" do
      before { sign_in owner }

      it "Memory が 1 件削除される" do
        expect {
          delete memory_path(uuid: target.uuid)
        }.to change(Memory, :count).by(-1)
      end

      it "memories_path にリダイレクト + flash[:notice] が立つ" do
        delete memory_path(uuid: target.uuid)
        expect(response).to redirect_to(memories_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "他人" do
      before { sign_in stranger }

      it "認可エラーで root へリダイレクト + Memory は残る" do
        expect {
          delete memory_path(uuid: target.uuid)
        }.not_to change(Memory, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
