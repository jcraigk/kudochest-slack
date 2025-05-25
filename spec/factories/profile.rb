FactoryBot.define do
  factory :profile do
    team

    sequence(:real_name) { |n| "Real Name #{n}" }
    sequence(:display_name) { |n| "display-name-#{n}" }
    sequence(:email) { |n| "profile-#{n}@example.com" }
    rid { FactoryHelper.rid("U") }
    avatar_url { Faker::Internet.url }
  end
end
