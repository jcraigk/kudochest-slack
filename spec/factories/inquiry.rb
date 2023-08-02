FactoryBot.define do
  factory :inquiry do
    user

    subject { 'general' }
    body { Faker::Lorem.sentence(word_count: 25) }
  end
end
