require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション: name" do
    it "name が空文字なら invalid" do
      user = build(:user, name: "")
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "name が nil なら invalid" do
      user = build(:user, name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to be_present
    end

    it "name に値があれば valid（正常系）" do
      user = build(:user, name: "山田太郎")
      expect(user).to be_valid
    end
  end

  describe "バリデーション: Devise validatable の最低限スモーク" do
    # アプリ固有ではないが、依存ライブラリが想定通り効いていることを
    # 1〜2 例ずつ確認する（壊れたら気づける程度）
    it "email が空なら invalid（presence）" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "email の形式が不正なら invalid（format）" do
      user = build(:user, email: "not_an_email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "email が重複していると invalid（uniqueness）" do
      create(:user, email: "dup@example.com")
      user = build(:user, email: "dup@example.com")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "password が短すぎる（6文字未満）と invalid（length）" do
      user = build(:user, password: "12345")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to be_present
    end
  end

  describe "アソシエーション（宣言）" do
    it { is_expected.to have_many(:memories).dependent(:destroy) }
    it { is_expected.to have_many(:user_family_groups).dependent(:destroy) }
    it { is_expected.to have_many(:family_groups).through(:user_family_groups) }
    it { is_expected.to have_many(:reactions).dependent(:destroy) }
    it { is_expected.to have_many(:tags).dependent(:destroy) }
  end

  describe "アソシエーション（動作）" do
    let!(:user) { create(:user) }

    it "user 削除で memories も削除される（dependent: :destroy）" do
      create(:memory, user: user)
      expect { user.destroy }.to change(Memory, :count).by(-1)
    end

    it "user 削除で user_family_groups も削除される" do
      family_group = create(:family_group)
      create(:user_family_group, user: user, family_group: family_group)
      expect { user.destroy }.to change(UserFamilyGroup, :count).by(-1)
    end

    it "family_groups は user_family_groups 経由でアクセスできる（through）" do
      family_group = create(:family_group)
      create(:user_family_group, user: user, family_group: family_group)
      expect(user.family_groups).to include(family_group)
    end

    it "user 削除で reactions も削除される" do
      other_user = create(:user)
      memory = create(:memory, user: other_user)
      Reaction.create!(user: user, memory: memory, reaction_type: :thumbs_up)
      expect { user.destroy }.to change(Reaction, :count).by(-1)
    end

    it "user 削除で tags も削除される" do
      user.tags.create!(name: "テストタグ")
      expect { user.destroy }.to change(Tag, :count).by(-1)
    end
  end

  describe "avatar の content_type バリデーション" do
    let(:user) { build(:user) }

    it "avatar 未添付なら valid（factory デフォルト）" do
      expect(user).to be_valid
    end

    it "PNG / JPEG は valid（正常系）" do
      %w[image/png image/jpeg].each do |type|
        u = build(:user)
        u.avatar.attach(
          io: Rails.root.join("spec/fixtures/files/test_image_200x200.png").open,
          filename: "avatar.#{type.split('/').last}",
          content_type: type
        )
        expect(u).to be_valid, "#{type} should be valid"
      end
    end

    it "許可外の content_type は invalid（例: GIF は不可）" do
      user.avatar.attach(
        io: StringIO.new("malicious payload"),
        filename: "evil.gif",
        content_type: "image/gif"
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("はPNG、JPG、JPEG形式のみアップロード可能です")
    end
  end

  describe "avatar の size バリデーション（スタブ）" do
    let(:user) { build(:user) }

    before do
      user.avatar.attach(
        io: Rails.root.join("spec/fixtures/files/test_image_200x200.png").open,
        filename: "test_image_200x200.png",
        content_type: "image/png"
      )
    end

    it "MAX_AVATAR_SIZE ちょうどは valid（境界・スタブ）" do
      allow(user.avatar.blob).to receive(:byte_size).and_return(User::MAX_AVATAR_SIZE)
      expect(user).to be_valid
    end

    it "MAX_AVATAR_SIZE を超えると invalid（境界・スタブ）" do
      allow(user.avatar.blob).to receive(:byte_size).and_return(User::MAX_AVATAR_SIZE + 1)
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("は5MB以下にしてください")
    end
  end

  describe "avatar の size バリデーション（実バイト数）" do
    # スタブとは別に、Active Storage の byte_size 経由で本物の境界を確認する
    it "MAX_AVATAR_SIZE を超える実バイト列を attach すると invalid" do
      large_io = StringIO.new("\0" * (User::MAX_AVATAR_SIZE + 1))

      user = build(:user)
      user.avatar.attach(
        io: large_io,
        filename: "over_max.png",
        content_type: "image/png"
      )
      expect(user).not_to be_valid
      expect(user.errors[:avatar]).to include("は5MB以下にしてください")
    end
  end

  describe ".default_name_for" do
    it "line provider は LINEユーザー を返す" do
      expect(User.default_name_for("line")).to eq("LINEユーザー")
    end

    it "google_oauth2 provider は Googleユーザー を返す" do
      expect(User.default_name_for("google_oauth2")).to eq("Googleユーザー")
    end

    it "未知の provider はフォールバックで ユーザー を返す" do
      expect(User.default_name_for("twitter")).to eq("ユーザー")
    end
  end

  describe ".from_omniauth" do
    # omniauth の auth ハッシュは Hashie::Mash でメソッドアクセスできる構造のため、
    # OpenStruct で必要なメソッドだけ持つ偽物を作って模す（テストモードより軽量）。
    def build_auth(provider:, uid:, email:, name:)
      OpenStruct.new(
        provider: provider,
        uid: uid,
        info: OpenStruct.new(email: email, name: name)
      )
    end

    context "新規ユーザーで email / name が揃っているとき" do
      let(:auth) do
        build_auth(provider: "line", uid: "U1234567890",
                   email: "taro@example.com", name: "山田太郎")
      end

      it "新規 User を作成する" do
        expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
      end

      it "auth.info.email をそのまま使う" do
        user = User.from_omniauth(auth)
        expect(user.email).to eq("taro@example.com")
      end

      it "auth.info.name をそのまま使う" do
        user = User.from_omniauth(auth)
        expect(user.name).to eq("山田太郎")
      end

      it "provider と uid が保存される" do
        user = User.from_omniauth(auth)
        expect(user.provider).to eq("line")
        expect(user.uid).to eq("U1234567890")
      end
    end

    context "新規ユーザーで email が欠落しているとき" do
      let(:auth) do
        build_auth(provider: "line", uid: "U1234567890",
                   email: nil, name: "山田太郎")
      end

      # Devise の :database_authenticatable は保存前に email を downcase するため、
      # 期待値も小文字にする（LINE の uid は大文字始まりだが結果は全て小文字）
      it "uid-provider@example.com を fallback として使う（downcase 後）" do
        user = User.from_omniauth(auth)
        expect(user.email).to eq("u1234567890-line@example.com")
      end
    end

    context "新規ユーザーで name が欠落しているとき" do
      let(:auth) do
        build_auth(provider: "line", uid: "U1234567890",
                   email: "taro@example.com", name: nil)
      end

      it "provider 別のデフォルト名（LINEユーザー）に fallback する" do
        user = User.from_omniauth(auth)
        expect(user.name).to eq("LINEユーザー")
      end
    end

    context "新規ユーザーで google_oauth2 から name が欠落しているとき" do
      let(:auth) do
        build_auth(provider: "google_oauth2", uid: "google-uid-123",
                   email: "hanako@example.com", name: nil)
      end

      it "Googleユーザー に fallback する" do
        user = User.from_omniauth(auth)
        expect(user.name).to eq("Googleユーザー")
      end
    end

    context "既存ユーザーで provider/uid が一致するとき" do
      let!(:existing_user) do
        create(:user,
               provider: "line",
               uid: "U1234567890",
               email: "existing@example.com",
               name: "既存名")
      end

      let(:auth) do
        build_auth(provider: "line", uid: "U1234567890",
                   email: "ignored@example.com", name: "無視される名前")
      end

      it "新規作成せず既存ユーザーを返す" do
        expect { User.from_omniauth(auth) }.not_to change(User, :count)
      end

      it "既存ユーザーの email / name を上書きしない" do
        user = User.from_omniauth(auth)
        expect(user.email).to eq("existing@example.com")
        expect(user.name).to eq("既存名")
      end
    end
  end
end
