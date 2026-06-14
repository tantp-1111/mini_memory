FactoryBot.define do
  factory :user_family_group do
    user
    family_group
    role { :member }
  end
end
