require "rails_helper"

RSpec.describe "FamilyGroups", type: :request do
  # owner    … グループのオーナー
  # member   … グループのメンバー
  # outsider … どのグループにも未所属（= 新規作成が可能なユーザー）
  let(:group)    { create(:family_group) }
  let(:owner)    { create(:user) }
  let(:member)   { create(:user) }
  let(:outsider) { create(:user) }

  before do
    create(:user_family_group, user: owner,  family_group: group, role: :owner)
    create(:user_family_group, user: member, family_group: group, role: :member)
  end

  describe "GET /family_groups/new (new)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        get new_family_group_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "未所属ユーザーは 200" do
      sign_in outsider
      get new_family_group_path
      expect(response).to have_http_status(:ok)
    end

    it "既にグループ所属のユーザーは認可エラーで root へ" do
      sign_in owner
      get new_family_group_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /family_groups/:uuid/edit (edit)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        get edit_family_group_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "オーナーは 200" do
      sign_in owner
      get edit_family_group_path(group)
      expect(response).to have_http_status(:ok)
    end

    it "メンバーは認可エラーで root へ" do
      sign_in member
      get edit_family_group_path(group)
      expect(response).to redirect_to(root_path)
    end

    it "非メンバーは 404" do
      sign_in outsider
      get edit_family_group_path(group)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /family_groups (create)" do
    let(:valid_params)   { { family_group: { name: "あたらしい家族" } } }
    let(:invalid_params) { { family_group: { name: "" } } }

    context "未所属ユーザー" do
      before { sign_in outsider }

      it "正常系: Group とオーナーの所属が作成され show へリダイレクト" do
        expect {
          post family_groups_path, params: valid_params
        }.to change(FamilyGroup, :count).by(1)
         .and change(UserFamilyGroup, :count).by(1)
        expect(UserFamilyGroup.last).to have_attributes(user: outsider, role: "owner")
        expect(response).to redirect_to(family_group_path(FamilyGroup.last))
      end

      it "異常系: name 空は 422 で作成されない" do
        expect {
          post family_groups_path, params: invalid_params
        }.to change(FamilyGroup, :count).by(0).and change(UserFamilyGroup, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it "既に所属のユーザーは認可エラーで作成されず root へ" do
      sign_in owner
      expect {
        post family_groups_path, params: valid_params
      }.not_to change(FamilyGroup, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /family_groups/:uuid (show)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        get family_group_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "オーナーは 200" do
      sign_in owner
      get family_group_path(group)
      expect(response).to have_http_status(:ok)
    end

    it "メンバーは 200" do
      sign_in member
      get family_group_path(group)
      expect(response).to have_http_status(:ok)
    end

    it "非メンバーは 404" do
      sign_in outsider
      get family_group_path(group)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /family_groups/:uuid (update)" do
    context "オーナー" do
      before { sign_in owner }

      it "正常系: 名前が更新され show へリダイレクト" do
        patch family_group_path(group), params: { family_group: { name: "新しい名前" } }
        expect(group.reload.name).to eq("新しい名前")
        expect(response).to redirect_to(family_group_path(group))
      end

      it "異常系: name 空は 422 で更新されない" do
        patch family_group_path(group), params: { family_group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(group.reload.name).to eq("テスト家族")
      end
    end

    it "メンバーは認可エラーで更新されず root へ" do
      sign_in member
      patch family_group_path(group), params: { family_group: { name: "新しい名前" } }
      expect(response).to redirect_to(root_path)
      expect(group.reload.name).to eq("テスト家族")
    end

    it "非メンバーは 404" do
      sign_in outsider
      patch family_group_path(group), params: { family_group: { name: "新しい名前" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /family_groups/:uuid (destroy)" do
    it "オーナーは Group を削除し mypage へリダイレクト" do
      sign_in owner
      expect {
        delete family_group_path(group)
      }.to change(FamilyGroup, :count).by(-1)
      expect(response).to redirect_to(mypage_path)
    end

    it "メンバーは認可エラーで削除されない" do
      sign_in member
      expect {
        delete family_group_path(group)
      }.not_to change(FamilyGroup, :count)
      expect(response).to redirect_to(root_path)
    end

    it "非メンバーは 404" do
      sign_in outsider
      delete family_group_path(group)
      expect(response).to have_http_status(:not_found)
    end
  end
end
