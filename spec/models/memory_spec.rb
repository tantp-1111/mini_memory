require "rails_helper"

RSpec.describe Memory, type: :model do
  describe "バリデーション" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(255) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:memory_date) }
    it { is_expected.to validate_presence_of(:image) }
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:memory_children).dependent(:destroy) }
    it { is_expected.to have_many(:children).through(:memory_children) }
    it { is_expected.to have_many(:memory_tags).dependent(:destroy) }
    it { is_expected.to have_many(:tags).through(:memory_tags) }
  end

  describe "enum :visibility" do
    # CLAUDE.md の方針: 値は数値で固定し、後から再利用しない
    it "は private_only=0 / unlisted=1 / published=2 で固定" do
      expect(Memory.visibilities).to eq(
        "private_only" => 0,
        "unlisted" => 1,
        "published" => 2
      )
    end

    it "新規レコードのデフォルトは private_only" do
      expect(Memory.new.visibility).to eq("private_only")
    end
  end

  describe "#owned_by?" do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:memory) { build(:memory, user: owner) }

    it "投稿者本人なら true を返す" do
      expect(memory.owned_by?(owner)).to be true
    end

    it "別ユーザーなら false を返す" do
      expect(memory.owned_by?(other_user)).to be false
    end

    it "nil なら false を返す" do
      expect(memory.owned_by?(nil)).to be false
    end
  end

  describe "#reactable_by?" do
    let(:owner) { create(:user) }
    let(:other_user) { create(:user) }
    let(:memory) { build(:memory, user: owner) }

    it "ログイン中で他人の投稿なら true" do
      expect(memory.reactable_by?(other_user)).to be true
    end

    it "自分の投稿には反応できないので false" do
      expect(memory.reactable_by?(owner)).to be false
    end

    it "未ログイン (nil) は false" do
      expect(memory.reactable_by?(nil)).to be false
    end
  end
end
