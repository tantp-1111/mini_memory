require "rails_helper"

RSpec.describe MemoryPolicy, type: :policy do
  subject { described_class }

  # 登場人物のヘルパー
  # - owner             … Memory の投稿者
  # - family_member     … owner と同じ family_group に所属
  # - stranger          … どこの family_group にも属さない他人
  let(:owner)         { create(:user) }
  let(:family_member) { create(:user) }
  let(:stranger)      { create(:user) }
  let(:family_group)  { create(:family_group) }

  before do
    create(:user_family_group, user: owner,         family_group: family_group)
    create(:user_family_group, user: family_member, family_group: family_group)
    # stranger は意図的にどの family_group にも所属させない
  end

  # visibility 別の Memory を都度 build する
  def memory_with(visibility:, user: owner)
    build(:memory, user: user, visibility: visibility)
  end

  describe "permissions" do
    permissions :index? do
      it "未ログインでも true（コントローラ側で require_login する前提）" do
        expect(subject).to permit(nil, Memory.new)
      end

      it "ログイン済みなら true" do
        expect(subject).to permit(owner, Memory.new)
      end
    end

    permissions :show? do
      let(:memory) { memory_with(visibility: :private_only) }

      it "投稿者本人なら許可" do
        expect(subject).to permit(owner, memory)
      end

      it "別ユーザー（家族メンバーでも）は拒否" do
        expect(subject).not_to permit(family_member, memory)
      end

      it "未ログインは拒否" do
        expect(subject).not_to permit(nil, memory)
      end
    end

    permissions :create?, :new? do
      it "ログイン済みなら許可" do
        expect(subject).to permit(owner, Memory.new)
      end

      it "未ログインは拒否" do
        expect(subject).not_to permit(nil, Memory.new)
      end
    end

    permissions :update?, :edit?, :destroy? do
      let(:memory) { memory_with(visibility: :published) }

      it "投稿者本人なら許可" do
        expect(subject).to permit(owner, memory)
      end

      it "別ユーザーは拒否" do
        expect(subject).not_to permit(stranger, memory)
      end

      it "未ログインは拒否" do
        expect(subject).not_to permit(nil, memory)
      end
    end

    describe "family_show?" do
      context "private_only の Memory" do
        let(:memory) { memory_with(visibility: :private_only) }

        # private_only は family_show? の対象外（コメント参照）
        # owner も family_show? からは見えず、show? のみで閲覧する設計
        permissions :family_show? do
          it "owner でも拒否（private_only は family feed から除外）" do
            expect(subject).not_to permit(owner, memory)
          end

          it "家族メンバーも拒否" do
            expect(subject).not_to permit(family_member, memory)
          end

          it "他人は拒否" do
            expect(subject).not_to permit(stranger, memory)
          end
        end
      end

      context "unlisted の Memory" do
        let(:memory) { memory_with(visibility: :unlisted) }

        permissions :family_show? do
          it "家族メンバーは許可" do
            expect(subject).to permit(family_member, memory)
          end

          it "他人は拒否" do
            expect(subject).not_to permit(stranger, memory)
          end

          it "未ログインは拒否" do
            expect(subject).not_to permit(nil, memory)
          end
        end
      end

      context "published の Memory" do
        let(:memory) { memory_with(visibility: :published) }

        permissions :family_show? do
          it "家族メンバーは許可" do
            expect(subject).to permit(family_member, memory)
          end

          it "owner も家族メンバーとして許可" do
            expect(subject).to permit(owner, memory)
          end

          it "他人は拒否" do
            expect(subject).not_to permit(stranger, memory)
          end
        end
      end

      # family_show? の owner ケースを family_member_of_owner? に委ねた狙いを検証
      # 一覧 (FamilyFeedScope = 0 件) と詳細で挙動が食い違うのを防ぐ
      context "家族グループに未所属の owner（published Memory）" do
        let(:lonely_owner)  { create(:user) }
        let(:lonely_memory) { memory_with(visibility: :published, user: lonely_owner) }

        permissions :family_show? do
          it "owner であっても拒否（family feed 一覧と挙動を揃える）" do
            expect(subject).not_to permit(lonely_owner, lonely_memory)
          end
        end
      end
    end

    describe "react?" do
      context "published の Memory" do
        let(:memory) { memory_with(visibility: :published) }

        permissions :react? do
          it "他人なら許可（ログイン中 & 自分の投稿ではない）" do
            expect(subject).to permit(stranger, memory)
          end

          it "投稿者本人は拒否（自分の投稿には反応できない）" do
            expect(subject).not_to permit(owner, memory)
          end

          it "未ログインは拒否" do
            expect(subject).not_to permit(nil, memory)
          end
        end
      end

      context "private_only の Memory" do
        let(:memory) { memory_with(visibility: :private_only) }

        permissions :react? do
          it "他人でも拒否（公開されていない投稿は反応不可）" do
            expect(subject).not_to permit(stranger, memory)
          end
        end
      end

      context "unlisted の Memory" do
        let(:memory) { memory_with(visibility: :unlisted) }

        permissions :react? do
          it "他人でも拒否（react? は published のみ許可）" do
            expect(subject).not_to permit(stranger, memory)
          end
        end
      end
    end
  end

  describe MemoryPolicy::Scope do
    # /memories index 用 - 自分の投稿のみ
    let!(:own_private)   { create(:memory, user: owner,         visibility: :private_only) }
    let!(:own_unlisted)  { create(:memory, user: owner,         visibility: :unlisted) }
    let!(:own_published) { create(:memory, user: owner,         visibility: :published) }
    let!(:other_pub)     { create(:memory, user: family_member, visibility: :published) }

    it "未ログインなら 0 件" do
      expect(described_class.new(nil, Memory).resolve).to be_empty
    end

    it "owner には自分の Memory が visibility 問わず全て返る" do
      result = described_class.new(owner, Memory).resolve
      expect(result).to contain_exactly(own_private, own_unlisted, own_published)
    end

    it "他人の Memory は含まれない" do
      result = described_class.new(owner, Memory).resolve
      expect(result).not_to include(other_pub)
    end

    it "ActiveRecord::Relation を返す（チェーン可能であること）" do
      expect(described_class.new(owner, Memory).resolve).to be_a(ActiveRecord::Relation)
    end
  end

  describe MemoryPolicy::FamilyFeedScope do
    # /family_memories index 用 - 家族メンバー横断 (unlisted + published)
    let!(:owner_private)        { create(:memory, user: owner,         visibility: :private_only) }
    let!(:owner_unlisted)       { create(:memory, user: owner,         visibility: :unlisted) }
    let!(:owner_published)      { create(:memory, user: owner,         visibility: :published) }
    let!(:family_member_priv)   { create(:memory, user: family_member, visibility: :private_only) }
    let!(:family_member_pub)    { create(:memory, user: family_member, visibility: :published) }
    let!(:stranger_published)   { create(:memory, user: stranger,      visibility: :published) }

    it "未ログインなら 0 件" do
      expect(described_class.new(nil, Memory).resolve).to be_empty
    end

    it "家族メンバーの unlisted + published のみ返る（private_only は除外）" do
      result = described_class.new(family_member, Memory).resolve
      expect(result).to contain_exactly(owner_unlisted, owner_published, family_member_pub)
    end

    it "他家族グループ（stranger）の Memory は含まれない" do
      result = described_class.new(family_member, Memory).resolve
      expect(result).not_to include(stranger_published)
    end

    it "private_only は含まれない（owner 本人がフィルタしても自分の private は除外）" do
      result = described_class.new(owner, Memory).resolve
      expect(result).not_to include(owner_private)
    end

    context "family_group に未所属の user" do
      it "0 件（自分の published すら含まれない）" do
        expect(described_class.new(stranger, Memory).resolve).to be_empty
      end
    end
  end
end
