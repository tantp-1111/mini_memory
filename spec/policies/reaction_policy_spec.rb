require "rails_helper"

RSpec.describe ReactionPolicy, type: :policy do
  subject { described_class }

  let(:memory_author) { create(:user) }
  let(:reactor)       { create(:user) }
  let(:other_user)    { create(:user) }
  let(:memory)        { create(:memory, user: memory_author, visibility: :published) }
  let(:reaction)      { create(:reaction, user: reactor, memory: memory) }

  describe "permissions" do
    permissions :destroy? do
      it "自分のリアクションなら true" do
        expect(subject).to permit(reactor, reaction)
      end

      it "他人のリアクションは削除できない（false）" do
        expect(subject).not_to permit(other_user, reaction)
      end

      # 「リアクションを受けた投稿の作者」であっても削除権限はない
      it "memory の投稿者であっても他人のリアクションは削除できない（false）" do
        expect(subject).not_to permit(memory_author, reaction)
      end

      it "未ログインは false" do
        expect(subject).not_to permit(nil, reaction)
      end
    end
  end
end
