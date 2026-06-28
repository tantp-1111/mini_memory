require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:group)    { create(:family_group) }
  let(:owner)    { create(:user) }
  let(:member)   { create(:user) }
  let(:outsider) { create(:user) } # どのグループにも未所属（参加可能なユーザー）

  before do
    create(:user_family_group, user: owner,  family_group: group, role: :owner)
    create(:user_family_group, user: member, family_group: group, role: :member)
  end

  describe "POST /invitations (create = 招待リンク発行)" do
    context "未ログイン" do
      it "サインイン画面へリダイレクト" do
        post invitations_path, params: { family_group_id: group.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "オーナーは招待を発行でき、グループ詳細へリダイレクト" do
      sign_in owner
      expect {
        post invitations_path, params: { family_group_id: group.id }
      }.to change(Invitation, :count).by(1)
      expect(response).to redirect_to(family_group_path(group))
    end

    it "メンバーは認可エラーで発行されず root へ" do
      sign_in member
      expect {
        post invitations_path, params: { family_group_id: group.id }
      }.not_to change(Invitation, :count)
      expect(response).to redirect_to(root_path)
    end

    it "非メンバーは認可エラーで発行されず root へ" do
      sign_in outsider
      expect {
        post invitations_path, params: { family_group_id: group.id }
      }.not_to change(Invitation, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /invitations/:token (show = 招待リンク閲覧)" do
    let(:invitation) { create(:invitation, family_group: group) }

    it "有効なトークン + 未所属ユーザーは 200" do
      sign_in outsider
      get invitation_path(invitation.token)
      expect(response).to have_http_status(:ok)
    end

    it "未ログインはログイン要求でサインイン画面へ" do
      get invitation_path(invitation.token)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "既にグループ所属のユーザーは mypage へリダイレクト" do
      sign_in member
      get invitation_path(invitation.token)
      expect(response).to redirect_to(mypage_path)
    end

    it "期限切れトークンは root へリダイレクト" do
      invitation.update_column(:expires_at, 1.day.ago)
      sign_in outsider
      get invitation_path(invitation.token)
      expect(response).to redirect_to(root_path)
    end

    it "存在しないトークンは root へリダイレクト" do
      sign_in outsider
      get invitation_path("nonexistent-token")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /invitations/:token/join (join = 参加)" do
    let(:invitation) { create(:invitation, family_group: group) }

    it "未所属ユーザーは参加でき、mypage へリダイレクト" do
      sign_in outsider
      expect {
        post join_invitation_path(invitation.token)
      }.to change(UserFamilyGroup, :count).by(1)
      expect(outsider.reload.family_groups).to include(group)
      expect(response).to redirect_to(mypage_path)
    end

    it "既に所属のユーザーは参加できず mypage へリダイレクト" do
      sign_in member
      expect {
        post join_invitation_path(invitation.token)
      }.not_to change(UserFamilyGroup, :count)
      expect(response).to redirect_to(mypage_path)
    end

    it "未ログインはサインイン画面へ" do
      post join_invitation_path(invitation.token)
      expect(response).to redirect_to(new_user_session_path)
    end

    it "期限切れトークンは root へリダイレクト" do
      invitation.update_column(:expires_at, 1.day.ago)
      sign_in outsider
      post join_invitation_path(invitation.token)
      expect(response).to redirect_to(root_path)
    end

    it "存在しないトークンは root へリダイレクトし、参加しない" do
      sign_in outsider
      expect {
        post join_invitation_path("nonexistent-token")
      }.not_to change(UserFamilyGroup, :count)
      expect(response).to redirect_to(root_path)
    end
  end
end
