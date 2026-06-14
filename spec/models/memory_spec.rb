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

  describe "factory" do
    # factory はデフォルトで image を attach するので create でも save できる
    it "create(:memory) で永続化できる" do
      expect { create(:memory) }.to change(Memory, :count).by(1)
    end

    it "create(:memory) は uuid を URL パラメータとして返す" do
      memory = create(:memory)
      expect(memory.to_param).to eq(memory.uuid)
    end
  end

  describe "image の content_type バリデーション" do
    let(:memory) { build(:memory) }

    it "factory デフォルトの PNG は valid" do
      expect(memory).to be_valid
    end

    it "JPEG / WEBP も valid" do
      %w[image/jpeg image/webp].each do |type|
        m = build(:memory)
        m.image.attach(
          io: Rails.root.join("spec/fixtures/files/test_image_200x200.png").open,
          filename: "test.#{type.split('/').last}",
          content_type: type
        )
        expect(m).to be_valid, "#{type} should be valid"
      end
    end

    it "許可外の content_type は invalid" do
      memory.image.attach(
        io: StringIO.new("malicious payload"),
        filename: "evil.exe",
        content_type: "application/octet-stream"
      )
      expect(memory).not_to be_valid
      expect(memory.errors[:image]).to include("はJPEG、JPG、PNGのみアップロード可能です")
    end
  end

  describe "image の size バリデーション" do
    let(:memory) { build(:memory) }

    it "10MB ちょうどは valid" do
      allow(memory.image.blob).to receive(:byte_size).and_return(Memory::MAX_IMAGE_SIZE)
      expect(memory).to be_valid
    end

    it "10MB を超える image は invalid" do
      allow(memory.image.blob).to receive(:byte_size).and_return(Memory::MAX_IMAGE_SIZE + 1)
      expect(memory).not_to be_valid
      expect(memory.errors[:image]).to include("は10MB以下にしてください")
    end
  end

  describe "children_must_belong_to_user_family_group バリデーション" do
    let(:user) { create(:user) }
    let(:family_group) { create(:family_group) }
    before { create(:user_family_group, user: user, family_group: family_group) }

    it "children が空なら valid" do
      memory = build(:memory, user: user)
      expect(memory).to be_valid
    end

    it "user の家族グループに属する children なら valid" do
      child = create(:child, family_group: family_group)
      memory = build(:memory, user: user)
      memory.children = [ child ]
      expect(memory).to be_valid
    end

    it "user の家族グループに属さない children を紐付けると invalid" do
      other_group = create(:family_group)
      other_child = create(:child, family_group: other_group)
      memory = build(:memory, user: user)
      memory.children = [ other_child ]
      expect(memory).not_to be_valid
      expect(memory.errors[:children]).to be_present
    end
  end

end
