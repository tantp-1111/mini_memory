FactoryBot.define do
  factory :invitation do
    family_group
    # token / expires_at は Invitation#generate_token (before_create) で自動採番される
  end
end
