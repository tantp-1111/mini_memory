require "rails_helper"

RSpec.describe "UserFamilyGroups", type: :request do
  # owner    … グループのオーナー
  # co_owner … 2人目のオーナー（降格テスト用）
  # member   … 一般メンバー
  # outsider … 非メンバー（存在隠蔽で 404 になるべきユーザー）
  let(:group)    { create(:family_group) }
  let(:owner)    { create(:user) }
  let(:co_owner) { create(:user) }
  let(:member)   { create(:user) }
  let(:outsider) { create(:user) }

  let!(:owner_membership)    { create(:user_family_group, user: owner,    family_group: group, role: :owner) }
  let!(:co_owner_membership) { create(:user_family_group, user: co_owner, family_group: group, role: :owner) }
  let!(:member_membership)   { create(:user_family_group, user: member,   family_group: group, role: :member) }

  describe "PATCH /family_groups/:uuid/user_family_groups/:id (update = 役割変更)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        patch family_group_user_family_group_path(group, member_membership), params: { role: "owner" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "オーナー" do
      before { sign_in owner }

      it "メンバーをオーナーに昇格でき、show へリダイレクト" do
        patch family_group_user_family_group_path(group, member_membership), params: { role: "owner" }
        expect(member_membership.reload.role).to eq("owner")
        expect(response).to redirect_to(family_group_path(group))
      end

      it "別のオーナーをメンバーに降格できる" do
        patch family_group_user_family_group_path(group, co_owner_membership), params: { role: "member" }
        expect(co_owner_membership.reload.role).to eq("member")
        expect(response).to redirect_to(family_group_path(group))
      end
    end

    it "メンバーは認可エラーで変更されず root へ" do
      sign_in member
      patch family_group_user_family_group_path(group, co_owner_membership), params: { role: "member" }
      expect(response).to redirect_to(root_path)
      expect(co_owner_membership.reload.role).to eq("owner")
    end

    it "非メンバーは 404" do
      sign_in outsider
      patch family_group_user_family_group_path(group, member_membership), params: { role: "owner" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /family_groups/:uuid/user_family_groups/:id (destroy = 脱退・除名)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        delete family_group_user_family_group_path(group, member_membership)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "メンバーは自分自身を脱退でき、mypage へリダイレクト" do
      sign_in member
      expect {
        delete family_group_user_family_group_path(group, member_membership)
      }.to change(UserFamilyGroup, :count).by(-1)
      expect(response).to redirect_to(mypage_path)
    end

    it "オーナーは他メンバーを除名でき、show へリダイレクト" do
      sign_in owner
      expect {
        delete family_group_user_family_group_path(group, member_membership)
      }.to change(UserFamilyGroup, :count).by(-1)
      expect(response).to redirect_to(family_group_path(group))
    end

    it "メンバーは他メンバーを除名できず root へ" do
      sign_in member
      expect {
        delete family_group_user_family_group_path(group, co_owner_membership)
      }.not_to change(UserFamilyGroup, :count)
      expect(response).to redirect_to(root_path)
    end

    it "非メンバーは 404" do
      sign_in outsider
      delete family_group_user_family_group_path(group, member_membership)
      expect(response).to have_http_status(:not_found)
    end
  end
end
