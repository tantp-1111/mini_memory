require "rails_helper"

RSpec.describe "Children", type: :request do
  # owner    … グループのオーナー（こどもの作成/更新/削除が可能）
  # member   … グループのメンバー（閲覧のみ）
  # outsider … 非メンバー（存在を隠すため 404）
  let(:group)    { create(:family_group) }
  let(:owner)    { create(:user) }
  let(:member)   { create(:user) }
  let(:outsider) { create(:user) }
  let!(:child)   { create(:child, family_group: group, name: "そうた") }

  before do
    create(:user_family_group, user: owner,  family_group: group, role: :owner)
    create(:user_family_group, user: member, family_group: group, role: :member)
  end

  describe "GET /family_groups/:family_group_uuid/children (index)" do
    context "未ログイン" do
      it "サインイン画面にリダイレクトする" do
        get family_group_children_path(group)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "オーナー / メンバー" do
      it "オーナーは 200" do
        sign_in owner
        get family_group_children_path(group)
        expect(response).to have_http_status(:ok)
      end

      it "メンバーは 200" do
        sign_in member
        get family_group_children_path(group)
        expect(response).to have_http_status(:ok)
      end
    end

    context "非メンバー" do
      it "404（存在を隠す）" do
        sign_in outsider
        get family_group_children_path(group)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /family_groups/:family_group_uuid/children/new (new)" do
    it "オーナーは 200" do
      sign_in owner
      get new_family_group_child_path(group)
      expect(response).to have_http_status(:ok)
    end

    it "メンバーは認可エラーで root へ" do
      sign_in member
      get new_family_group_child_path(group)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /family_groups/:family_group_uuid/children (create)" do
    let(:valid_params)   { { child: { name: "あたらしいこども", birthday: "2020-01-01" } } }
    let(:invalid_params) { { child: { name: "" } } }

    context "オーナー" do
      before { sign_in owner }

      it "正常系: Child が 1 件作成され一覧へリダイレクト" do
        expect {
          post family_group_children_path(group), params: valid_params
        }.to change(Child, :count).by(1)
        expect(response).to redirect_to(family_group_children_path(group))
      end

      it "異常系: name 空は 422 で作成されない" do
        expect {
          post family_group_children_path(group), params: invalid_params
        }.not_to change(Child, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "メンバー" do
      before { sign_in member }

      it "認可エラーで作成されず root へ" do
        expect {
          post family_group_children_path(group), params: valid_params
        }.not_to change(Child, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /family_groups/:family_group_uuid/children/:uuid/edit (edit)" do
    it "オーナーは 200" do
      sign_in owner
      get edit_family_group_child_path(group, child)
      expect(response).to have_http_status(:ok)
    end

    it "メンバーは認可エラーで root へ" do
      sign_in member
      get edit_family_group_child_path(group, child)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /family_groups/:family_group_uuid/children/:uuid (update)" do
    context "オーナー" do
      before { sign_in owner }

      it "正常系: 名前が更新され一覧へリダイレクト" do
        patch family_group_child_path(group, child), params: { child: { name: "ゆうと" } }
        expect(child.reload.name).to eq("ゆうと")
        expect(response).to redirect_to(family_group_children_path(group))
      end

      it "異常系: name 空は 422 で更新されない" do
        patch family_group_child_path(group, child), params: { child: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(child.reload.name).to eq("そうた")
      end
    end

    it "メンバーは認可エラーで root へ" do
      sign_in member
      patch family_group_child_path(group, child), params: { child: { name: "ゆうと" } }
      expect(response).to redirect_to(root_path)
      expect(child.reload.name).to eq("そうた")
    end
  end

  describe "DELETE /family_groups/:family_group_uuid/children/:uuid (destroy)" do
    it "オーナーは Child を 1 件削除" do
      sign_in owner
      expect {
        delete family_group_child_path(group, child)
      }.to change(Child, :count).by(-1)
      expect(response).to redirect_to(family_group_children_path(group))
    end

    it "メンバーは認可エラーで削除されない" do
      sign_in member
      expect {
        delete family_group_child_path(group, child)
      }.not_to change(Child, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
