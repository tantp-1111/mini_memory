FactoryBot.define do
  factory :memory do
    title { "タイトル" }
    description { "エピソードの説明文" }
    memory_date { Date.current }
    visibility { :private_only }
    user
  end
end
