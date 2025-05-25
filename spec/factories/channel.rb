FactoryBot.define do
  factory :channel do
    team

    sequence(:name) { |n| "channel-#{n}" }
    rid { FactoryHelper.rid("C") }
  end
end
