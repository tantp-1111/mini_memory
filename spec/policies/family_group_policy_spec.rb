require "rails_helper"

RSpec.describe FamilyGroupPolicy, type: :policy do
  subject { described_class }

  let(:group_a)  { create(:family_group) }
  let(:group_b)  { create(:family_group) }
  let(:a_owner)  { create(:user) }
  let(:a_member) { create(:user) }
  let(:b_owner)  { create(:user) }
  let(:stranger) { create(:user) } # どのグループにも属さない

  before do
    create(:user_family_group, user: a_owner,  family_group: group_a, role: :owner)
    create(:user_family_group, user: a_member, family_group: group_a, role: :member)
    create(:user_family_group, user: b_owner,  family_group: group_b, role: :owner)
  end

  describe "permissions" do
    permissions :index? do
      it "ログイン済みなら true（所属有無は問わない）" do
        expect(subject).to permit(stranger, FamilyGroup.new)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, FamilyGroup.new)
      end
    end

    permissions :show? do
      it "所属メンバー（owner）なら true" do
        expect(subject).to permit(a_owner, group_a)
      end

      it "所属メンバー（member）なら true" do
        expect(subject).to permit(a_member, group_a)
      end

      it "別グループの owner は false" do
        expect(subject).not_to permit(b_owner, group_a)
      end

      it "未所属の user は false" do
        expect(subject).not_to permit(stranger, group_a)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, group_a)
      end
    end

    permissions :create?, :new? do
      # 1 ユーザー 1 グループ制約: 未所属の user のみ作成可能
      it "未所属の user なら true" do
        expect(subject).to permit(stranger, FamilyGroup.new)
      end

      it "既に owner として所属している user は false" do
        expect(subject).not_to permit(a_owner, FamilyGroup.new)
      end

      it "既に member として所属している user は false" do
        expect(subject).not_to permit(a_member, FamilyGroup.new)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, FamilyGroup.new)
      end
    end

    permissions :update?, :edit? do
      it "owner なら true" do
        expect(subject).to permit(a_owner, group_a)
      end

      it "member は false（ロール権限が必要）" do
        expect(subject).not_to permit(a_member, group_a)
      end

      it "別グループの owner は false" do
        expect(subject).not_to permit(b_owner, group_a)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, group_a)
      end
    end

    permissions :destroy? do
      it "owner なら true" do
        expect(subject).to permit(a_owner, group_a)
      end

      it "member は false（グループ削除はできない）" do
        expect(subject).not_to permit(a_member, group_a)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, group_a)
      end
    end
  end

  describe FamilyGroupPolicy::Scope do
    it "未ログインなら 0 件" do
      expect(described_class.new(nil, FamilyGroup).resolve).to be_empty
    end

    it "owner には自分の所属グループが返る" do
      result = described_class.new(a_owner, FamilyGroup).resolve
      expect(result).to contain_exactly(group_a)
    end

    it "member にも自分の所属グループが返る（owner/member で差はない）" do
      result = described_class.new(a_member, FamilyGroup).resolve
      expect(result).to contain_exactly(group_a)
    end

    it "別グループの owner からは自グループのみ見える" do
      result = described_class.new(b_owner, FamilyGroup).resolve
      expect(result).to contain_exactly(group_b)
    end

    it "未所属の user は 0 件" do
      expect(described_class.new(stranger, FamilyGroup).resolve).to be_empty
    end
  end
end
