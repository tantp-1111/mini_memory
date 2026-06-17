require "rails_helper"

RSpec.describe InvitationPolicy, type: :policy do
  subject { described_class }

  let(:group_a)  { create(:family_group) }
  let(:group_b)  { create(:family_group) }
  let(:a_owner)  { create(:user) }
  let(:a_member) { create(:user) }
  let(:b_owner)  { create(:user) }
  let(:stranger) { create(:user) }

  before do
    create(:user_family_group, user: a_owner,  family_group: group_a, role: :owner)
    create(:user_family_group, user: a_member, family_group: group_a, role: :member)
    create(:user_family_group, user: b_owner,  family_group: group_b, role: :owner)
  end

  let(:invitation_a) { create(:invitation, family_group: group_a) }
  let(:invitation_b) { create(:invitation, family_group: group_b) }

  # 招待リンクの発行・閲覧・削除は全て group_owner? を要求するため、
  # 4 つの permission をひとまとめに同じ user 種別で検証する
  describe "permissions (index? / show? / create? / destroy?)" do
    permissions :index?, :show?, :create?, :destroy? do
      it "同じグループの owner なら true" do
        expect(subject).to permit(a_owner, invitation_a)
      end

      it "同じグループの member は false（owner だけが招待を扱える）" do
        expect(subject).not_to permit(a_member, invitation_a)
      end

      it "別グループの owner は false" do
        expect(subject).not_to permit(b_owner, invitation_a)
      end

      it "未所属の user は false" do
        expect(subject).not_to permit(stranger, invitation_a)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, invitation_a)
      end
    end
  end

  describe InvitationPolicy::Scope do
    let!(:inv_a) { create(:invitation, family_group: group_a) }
    let!(:inv_b) { create(:invitation, family_group: group_b) }

    it "未ログインなら 0 件" do
      expect(described_class.new(nil, Invitation).resolve).to be_empty
    end

    it "owner には自分が owner であるグループの招待が返る" do
      result = described_class.new(a_owner, Invitation).resolve
      expect(result).to contain_exactly(inv_a)
    end

    it "別グループの owner からは自グループの招待のみ見える" do
      result = described_class.new(b_owner, Invitation).resolve
      expect(result).to contain_exactly(inv_b)
    end

    # owner と member を区別するスコープであることの保証
    it "member は 0 件（同じグループでも owner ロールがなければ招待は見えない）" do
      expect(described_class.new(a_member, Invitation).resolve).to be_empty
    end

    it "未所属の user は 0 件" do
      expect(described_class.new(stranger, Invitation).resolve).to be_empty
    end
  end
end
