require "rails_helper"

RSpec.describe UserFamilyGroupPolicy, type: :policy do
  subject { described_class }

  # 登場人物
  # - group_a / group_b の 2 つの家族グループ
  # - group_a に owner (a_owner) と member (a_member) を所属させる
  # - group_b に owner (b_owner) を所属させる（別グループの owner）
  # - stranger はどこにも所属しない
  let(:group_a)  { create(:family_group) }
  let(:group_b)  { create(:family_group) }
  let(:a_owner)  { create(:user) }
  let(:a_member) { create(:user) }
  let(:b_owner)  { create(:user) }
  let(:stranger) { create(:user) }

  let!(:a_owner_membership)  { create(:user_family_group, user: a_owner,  family_group: group_a, role: :owner) }
  let!(:a_member_membership) { create(:user_family_group, user: a_member, family_group: group_a, role: :member) }
  let!(:b_owner_membership)  { create(:user_family_group, user: b_owner,  family_group: group_b, role: :owner) }

  describe "permissions" do
    permissions :show? do
      it "同じグループの owner なら true" do
        expect(subject).to permit(a_owner, a_member_membership)
      end

      it "同じグループの member 同士でも true（same_group_member）" do
        expect(subject).to permit(a_member, a_owner_membership)
      end

      it "別グループのメンバーシップは false" do
        expect(subject).not_to permit(a_owner, b_owner_membership)
      end

      it "未所属の user は false" do
        expect(subject).not_to permit(stranger, a_owner_membership)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, a_owner_membership)
      end
    end

    permissions :create? do
      # 招待経由の自己参加を許可するため、record.user_id == 自分自身のみ true
      it "自分自身のメンバーシップを作るなら true" do
        new_membership = build(:user_family_group, user: stranger, family_group: group_a)
        expect(subject).to permit(stranger, new_membership)
      end

      it "他人のメンバーシップを作ろうとすると false（なりすまし禁止）" do
        new_membership = build(:user_family_group, user: a_member, family_group: group_a)
        expect(subject).not_to permit(stranger, new_membership)
      end

      it "未ログインは false" do
        new_membership = build(:user_family_group, user: stranger, family_group: group_a)
        expect(subject).not_to permit(nil, new_membership)
      end
    end

    permissions :update? do
      # group_owner? のみ許可。member が自分のロールを書き換えて owner 昇格できない保証も兼ねる
      it "同じグループの owner なら true" do
        expect(subject).to permit(a_owner, a_member_membership)
      end

      it "同じグループの member は false（ロール昇格できない）" do
        expect(subject).not_to permit(a_member, a_member_membership)
      end

      it "別グループの owner は false" do
        expect(subject).not_to permit(b_owner, a_member_membership)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, a_member_membership)
      end
    end

    permissions :destroy? do
      # self_membership? || group_owner? — 自己脱退と owner による kick の両方を許可
      it "自分自身のメンバーシップ（自己脱退）なら true" do
        expect(subject).to permit(a_member, a_member_membership)
      end

      it "同じグループの owner が member を削除（kick）なら true" do
        expect(subject).to permit(a_owner, a_member_membership)
      end

      it "同じグループの member が他人を削除しようとしたら false" do
        expect(subject).not_to permit(a_member, a_owner_membership)
      end

      it "別グループの owner は false" do
        expect(subject).not_to permit(b_owner, a_member_membership)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, a_member_membership)
      end
    end

    permissions :leave? do
      # 自分自身のメンバーシップに対する操作のみ true（view の脱退ボタン表示判定）
      it "自分自身のメンバーシップなら true" do
        expect(subject).to permit(a_member, a_member_membership)
      end

      it "他人のメンバーシップは false（owner であっても他人の leave ボタンは出さない）" do
        expect(subject).not_to permit(a_owner, a_member_membership)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, a_member_membership)
      end
    end

    permissions :kick? do
      # group_owner? && !self_membership? — 自分自身を kick できないように除外
      it "同じグループの owner が他のメンバーを kick なら true" do
        expect(subject).to permit(a_owner, a_member_membership)
      end

      it "owner が自分自身を kick しようとしても false（kick ボタンを自行に出さない）" do
        expect(subject).not_to permit(a_owner, a_owner_membership)
      end

      it "member は kick できない（false）" do
        expect(subject).not_to permit(a_member, a_owner_membership)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, a_member_membership)
      end
    end
  end

  describe UserFamilyGroupPolicy::Scope do
    it "未ログインなら 0 件" do
      expect(described_class.new(nil, UserFamilyGroup).resolve).to be_empty
    end

    it "owner には同じグループの全メンバーシップが返る" do
      result = described_class.new(a_owner, UserFamilyGroup).resolve
      expect(result).to contain_exactly(a_owner_membership, a_member_membership)
    end

    it "member にも同じグループの全メンバーシップが返る（owner/member で見え方は同じ）" do
      result = described_class.new(a_member, UserFamilyGroup).resolve
      expect(result).to contain_exactly(a_owner_membership, a_member_membership)
    end

    it "別グループのメンバーシップは含まれない" do
      result = described_class.new(a_owner, UserFamilyGroup).resolve
      expect(result).not_to include(b_owner_membership)
    end

    it "未所属の user は 0 件" do
      expect(described_class.new(stranger, UserFamilyGroup).resolve).to be_empty
    end
  end
end
