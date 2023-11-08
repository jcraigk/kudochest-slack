FactoryBot.define do
  factory :inquiry do
    profile

    subject { 'general' }
    body { Faker::Lorem.sentence(word_count: 25) }
  end
end
