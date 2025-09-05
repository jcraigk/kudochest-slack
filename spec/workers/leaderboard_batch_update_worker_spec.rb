require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe LeaderboardBatchUpdateWorker do
  let(:team) { create(:team) }
  let(:worker) { described_class.new }

  before do
    Sidekiq::Testing.fake!
    described_class.clear
    # Clean up Redis keys for this team
    REDIS.keys("leaderboard_*:#{team.id}:*").each { |key| REDIS.del(key) }
    REDIS.keys("leaderboard/#{team.id}/*").each { |key| REDIS.del(key) }
  end

  after do
    Sidekiq::Testing.inline!
    # Clean up Redis keys for this team
    REDIS.keys("leaderboard_*:#{team.id}:*").each { |key| REDIS.del(key) }
    REDIS.keys("leaderboard/#{team.id}/*").each { |key| REDIS.del(key) }
  end

  describe '#perform' do
    context 'when not recently updated' do
      it 'refreshes the leaderboard immediately' do
        expect_any_instance_of(LeaderboardRefreshWorker).to receive(:perform)
          .with(team.id, false, false)

        worker.perform(team.id, false, false)

        # Should mark as updated
        update_key = "leaderboard_updated:#{team.id}:points_received"
        expect(REDIS.get(update_key)).not_to be_nil
      end
    end

    context 'when recently updated' do
      before do
        # Mark as recently updated
        update_key = "leaderboard_updated:#{team.id}:points_received"
        REDIS.setex(update_key, 60, Time.current.to_i)

        # Mock cache to return metadata so it doesn't force refresh
        cache_double = instance_double(Cache::Leaderboard)
        allow(Cache::Leaderboard).to receive(:new).and_return(cache_double)
        allow(cache_double).to receive(:get_metadata).and_return({ updated_at: Time.current.to_i })
      end

      it 'schedules a delayed update for eventual consistency' do
        expect_any_instance_of(LeaderboardRefreshWorker).not_to receive(:perform)

        worker.perform(team.id, false, false)

        # Should have scheduled a delayed job
        expect(described_class.jobs.size).to eq(1)
        job = described_class.jobs.first
        expect(job['args']).to eq([ team.id, false, false ])
        expect(job['at']).to be > Time.current.to_f

        # Should have set delayed update key
        delayed_key = "leaderboard_delayed:#{team.id}:points_received"
        expect(REDIS.get(delayed_key)).not_to be_nil
      end

      it 'does not schedule multiple delayed updates' do
        # First call schedules delayed update
        worker.perform(team.id, false, false)
        expect(described_class.jobs.size).to eq(1)

        # Second call should not schedule another
        worker.perform(team.id, false, false)
        expect(described_class.jobs.size).to eq(1)
      end
    end

    context 'when performing scheduled delayed update' do
      it 'clears the delayed update key after refresh' do
        delayed_key = "leaderboard_delayed:#{team.id}:points_received"
        REDIS.setex(delayed_key, 60, "1")

        expect_any_instance_of(LeaderboardRefreshWorker).to receive(:perform)
          .with(team.id, false, false)

        worker.perform(team.id, false, false)

        # Should have cleared the delayed key
        expect(REDIS.get(delayed_key)).to be_nil
      end
    end

    context 'with different leaderboard types' do
      it 'tracks updates separately for each type' do
        # Update points received
        worker.perform(team.id, false, false)

        # Points sent should still update (different type)
        expect_any_instance_of(LeaderboardRefreshWorker).to receive(:perform)
          .with(team.id, true, false)

        worker.perform(team.id, true, false)
      end
    end
  end
end
