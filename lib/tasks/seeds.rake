namespace :seeds do
  include FactoryBot::Syntax::Methods

  desc 'Generate seeds for testing'
  task all: :environment do
    Rake::Task['seeds:topics'].execute
    Rake::Task['seeds:tips'].execute
    Rake::Task['seeds:loot'].execute
  end

  desc 'Generate Tips and related data for testing'
  task tips: :environment do
    tips = []
    team = Team.first
    print 'Generating Tips...'
    profiles = team.profiles.active
    profiles.each do |profile|
      profile_tips = []
      profile.update!(tokens: 1_000) if team.throttle_tips?
      rand(20..50).times do
        channel = team.channels.sample
        topic_id = rand(3).zero? ? nil : team.topics.sample&.id
        quantity = team.enable_jabs? ? (-1..5).to_a.reject(&:zero?).sample : rand(1..5)
        profile_tips += TipFactory.call \
          topic_id:,
          from_profile: profile,
          to_entity: 'Profile',
          to_profiles: [(profiles - [profile]).sample],
          from_channel_rid: channel.rid,
          from_channel_name: channel.name,
          quantity:,
          note: Faker::Lorem.sentence(word_count: rand(4..8)),
          event_ts: Time.current.to_f.to_s,
          channel_rid: channel.rid,
          source: 'seed',
          timestamp: Time.current
      end
      TipOutcomeService.call(tips: profile_tips)
      tips += profile_tips
      profile.update!(tokens: team.token_quantity)
    end
    puts 'done'

    print 'Randomizing temporal distribution of Tips...'
    tips.each do |tip|
      tip.update_columns(created_at: Time.current - rand(1..1_728_000).seconds) # up to 20 days
    end
    profiles.each do |profile|
      last_tip_received_at = profile.tips_received.order(created_at: :desc).first.created_at
      profile.update(last_tip_received_at:)
    end

    puts 'done'
  end

  desc 'Generate Topics for testing'
  task topics: :environment do
    print 'Generating topics'
    team = Team.first
    rand(5..30).times do
      create(:topic, team:)
    end
  end

  desc 'Generate Loot for testing'
  task loot: :environment do
    prices = [50, 100, 200, 250, 500, 1_000, 1_200]
    team = Team.first
    profile1 = team.profiles.active.first
    profile2 = team.profiles.active.second
    print 'Generating rewards'
    40.times do |n|
      auto_fulfill = rand(3).to_i == 1
      fulfillment_keys = Array.new(5) { Faker::Crypto.md5 }
      quantity = n.even? ? 0 : rand(100).to_i
      reward = Reward.create \
        team:,
        name: "Reward #{Faker::Crypto.md5.first(5)}",
        price: prices.sample,
        description: Faker::Lorem.paragraph,
        auto_fulfill:,
        quantity:,
        fulfillment_keys: auto_fulfill ? fulfillment_keys.join("\n") : nil,
        active: rand(3).to_i != 1
      next if rand(3).to_i.positive? || ENV.fetch('SKIP_CLAIMS', nil).present?
      fulfilled = auto_fulfill ? true : rand(2).to_i.even?
      max_claims = auto_fulfill ? fulfillment_keys.size : quantity
      num_claims = rand(2).to_i.even? ? max_claims : rand(max_claims).to_i
      num_claims.times do |c|
        reward.claims.create \
          profile: rand(2).to_i.even? ? profile1 : profile2,
          fulfilled_at: fulfilled ? Time.current : nil,
          fulfillment_key: fulfilled ? fulfillment_keys[c] : nil,
          price: reward.price
      end
    end

    puts 'done'
  end
end
