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

  describe "#sync_tags_from_input (after_save)" do
    let(:user) { create(:user) }

    it "tag_list_input が nil なら何もしない（early return）" do
      memory = create(:memory, user: user, tag_list_input: nil)
      expect(memory.tags).to be_empty
    end

    it "空文字または空白のみは 0 件" do
      memory = create(:memory, user: user, tag_list_input: "")
      expect(memory.tags).to be_empty
    end

    it "空白カンマのみの入力も 0 件（reject(&:blank?)）" do
      memory = create(:memory, user: user, tag_list_input: "  ,  ,  ")
      expect(memory.tags).to be_empty
    end

    it "カンマ区切り入力からタグを作成する" do
      memory = create(:memory, user: user, tag_list_input: "どんぐり,葉っぱ,折り紙")
      expect(memory.tags.map(&:name)).to contain_exactly("どんぐり", "葉っぱ", "折り紙")
    end

    it "各タグの前後の空白は strip される" do
      memory = create(:memory, user: user, tag_list_input: " どんぐり , 葉っぱ ")
      expect(memory.tags.map(&:name)).to contain_exactly("どんぐり", "葉っぱ")
    end

    it "重複したタグは除外される" do
      memory = create(:memory, user: user, tag_list_input: "どんぐり,どんぐり,葉っぱ")
      expect(memory.tags.map(&:name)).to contain_exactly("どんぐり", "葉っぱ")
    end

    it "TAG_LIMIT (10) を超える分は無視される" do
      names = (1..15).map { |n| "tag#{n}" }
      memory = create(:memory, user: user, tag_list_input: names.join(","))
      expect(memory.tags.count).to eq(Memory::TAG_LIMIT)
      expect(memory.tags.map(&:name)).to contain_exactly(*names.first(Memory::TAG_LIMIT))
    end

    it "TAG_MAX_LENGTH (30) を超えるタグは黙って無視される" do
      long_name = "あ" * (Memory::TAG_MAX_LENGTH + 1)
      memory = create(:memory, user: user, tag_list_input: "#{long_name},短いタグ")
      expect(memory.tags.map(&:name)).to contain_exactly("短いタグ")
    end

    it "作成されたタグは投稿者の user に紐付く" do
      memory = create(:memory, user: user, tag_list_input: "テスト")
      expect(memory.tags.first.user).to eq(user)
    end

    it "既存タグがあれば再作成せず参照する（find_or_create_by!）" do
      user.tags.create!(name: "既存")
      expect {
        create(:memory, user: user, tag_list_input: "既存,新規")
      }.to change { user.tags.count }.by(1) # 新規 1 件のみ追加
    end
  end
end
