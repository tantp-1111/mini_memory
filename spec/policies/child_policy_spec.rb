require "rails_helper"

RSpec.describe ChildPolicy, type: :policy do
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

  let(:child_a) { create(:child, family_group: group_a) }
  let(:child_b) { create(:child, family_group: group_b) }

  describe "permissions" do
    # 親リソース(FamilyGroup) のメンバー検証は controller の before_action で行う設計のため、
    # Policy 単体では index? / show? は常に true。
    permissions :index?, :show? do
      it "ログイン状態を問わず true（実際の閲覧制御は controller で行う設計）" do
        expect(subject).to permit(stranger, child_a)
        expect(subject).to permit(nil,      child_a)
      end
    end

    # 書き込み系は owner のみ。member は閲覧できても child を編集・削除できない
    permissions :create?, :new?, :update?, :edit?, :destroy? do
      it "同じグループの owner なら true" do
        expect(subject).to permit(a_owner, child_a)
      end

      it "同じグループの member は false（閲覧はできるが書き込み不可）" do
        expect(subject).not_to permit(a_member, child_a)
      end

      it "別グループの owner は false" do
        expect(subject).not_to permit(b_owner, child_a)
      end

      it "未所属の user は false" do
        expect(subject).not_to permit(stranger, child_a)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, child_a)
      end
    end
  end

  describe ChildPolicy::Scope do
    let!(:child_a1) { create(:child, family_group: group_a) }
    let!(:child_a2) { create(:child, family_group: group_a) }
    let!(:child_b1) { create(:child, family_group: group_b) }

    it "未ログインなら 0 件" do
      expect(described_class.new(nil, Child).resolve).to be_empty
    end

    it "owner には自グループの子全てが返る" do
      result = described_class.new(a_owner, Child).resolve
      expect(result).to contain_exactly(child_a1, child_a2)
    end

    it "member にも自グループの子全てが返る（閲覧は member も可）" do
      result = described_class.new(a_member, Child).resolve
      expect(result).to contain_exactly(child_a1, child_a2)
    end

    it "別グループの子は含まれない" do
      result = described_class.new(a_owner, Child).resolve
      expect(result).not_to include(child_b1)
    end

    # 早期 return の動作確認
    it "family_group 未所属の user は 0 件（pluck が空配列 → 早期 return）" do
      expect(described_class.new(stranger, Child).resolve).to be_empty
    end
  end
end
