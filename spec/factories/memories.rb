FactoryBot.define do
  factory :memory do
    title { "タイトル" }
    description { "エピソードの説明文" }
    memory_date { Date.current }
    visibility { :private_only }
    user

    # Memory は image presence バリデーションを持つため、
    # build / create どちらでも使えるようデフォルトでテスト画像を添付する
    after(:build) do |memory|
      memory.image.attach(
        io: Rails.root.join("spec/fixtures/files/test_image_200x200.png").open,
        filename: "test_image_200x200.png",
        content_type: "image/png"
      )
    end
  end
end
