FactoryBot.define do
  factory :reaction do
    user
    memory
    reaction_type { :thumbs_up }
  end
end
