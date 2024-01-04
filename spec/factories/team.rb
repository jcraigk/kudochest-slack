FactoryBot.define do
  factory :team do
    platform { 'slack' }
    sequence(:name) { |n| "Team #{n}" }
    rid { FactoryHelper.rid(platform, 'T') }
    avatar_url { Faker::Internet.url }
    api_key { SecureRandom.hex }
    app_profile_rid { FactoryHelper.rid(platform, 'U') }
    max_level { App.default_max_level }
    max_level_points { App.default_max_level_points }
    trial_expires_at { App.trial_period.from_now }
    time_zone { 'UTC' }
    enable_jabs { true }
    deduct_jabs { true }

    trait :with_admin do
      after(:build) do |team|
        build(:profile, team:, admin: true)
      end
    end

    trait :with_profiles do
      after(:create) do |team|
        team.profiles += create_list(:profile, 3)
      end
    end

    trait :with_app_profile do
      after(:create) do |team|
        team.profiles << create(:profile, rid: team.app_profile_rid)
      end
    end
  end
end
