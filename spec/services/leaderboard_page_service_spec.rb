require 'rails_helper'

RSpec.describe LeaderboardPageService do
  subject(:service) { described_class.call(**args) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:cache_data) { LeaderboardPage.new(Time.current.to_i, profiles) }
  let(:cache_giving_data) { LeaderboardPage.new(Time.current.to_i, giving_profiles) }
  let(:cache_jab_data) { LeaderboardPage.new(Time.current.to_i, jab_profiles) }
  let(:mock_cache) { instance_spy(Cache::Leaderboard) }
  let(:mock_giving_cache) { instance_spy(Cache::Leaderboard) }
  let(:mock_jab_cache) { instance_spy(Cache::Leaderboard) }
  let(:profiles) do
    [
      LeaderboardProfile.new(id: 1, slug: 'profile1'),
      LeaderboardProfile.new(id: 2, slug: 'profile2'),
      LeaderboardProfile.new(id: 3, slug: 'profile3'),
      LeaderboardProfile.new(id: 4, slug: 'profile4'),
      LeaderboardProfile.new(id: 5, slug: 'profile5')
    ]
  end
  let(:giving_profiles) do
    [
      LeaderboardProfile.new(id: 3, slug: 'profile3'),
      LeaderboardProfile.new(id: 4, slug: 'profile4'),
      LeaderboardProfile.new(id: 5, slug: 'profile5')
    ]
  end
  let(:jab_profiles) do
    [
      LeaderboardProfile.new(id: 4, slug: 'profile4'),
      LeaderboardProfile.new(id: 3, slug: 'profile3'),
      LeaderboardProfile.new(id: 5, slug: 'profile5')
    ]
  end
  let(:result_ids) { service.profiles.pluck(:id) }

  before do
    allow(Cache::Leaderboard).to \
      receive(:new).with(team.id, false, false).and_return(mock_cache)
    allow(Cache::Leaderboard).to \
      receive(:new).with(team.id, true, false).and_return(mock_giving_cache)
    allow(Cache::Leaderboard).to \
      receive(:new).with(team.id, false, true).and_return(mock_jab_cache)
    # Mock metadata for all cache instances
    metadata = { updated_at: Time.current.to_i, total_pages: 1, total_profiles: profiles.size, page_size: 100 }
    giving_metadata = { updated_at: Time.current.to_i, total_pages: 1, total_profiles: giving_profiles.size, page_size: 100 }
    jab_metadata = { updated_at: Time.current.to_i, total_pages: 1, total_profiles: jab_profiles.size, page_size: 100 }

    allow(mock_cache).to receive(:get_metadata).and_return(metadata)
    allow(mock_cache).to receive(:get_page).with(1).and_return(profiles)

    allow(mock_giving_cache).to receive(:get_metadata).and_return(giving_metadata)
    allow(mock_giving_cache).to receive(:get_page).with(1).and_return(giving_profiles)

    allow(mock_jab_cache).to receive(:get_metadata).and_return(jab_metadata)
    allow(mock_jab_cache).to receive(:get_page).with(1).and_return(jab_profiles)
  end

  shared_examples 'success' do
    it 'returns expectd leaderboard page' do
      expect(result_ids).to eq(expected_ids)
    end
  end

  context 'when count is given, truncates the list' do
    let(:args) { { team:, count: 3 } }
    let(:expected_ids) { [ 1, 2, 3 ] }

    it_behaves_like 'success'
  end

  context 'when profile and count are given, contextual page is returned' do
    let(:args) { { team:, profile: profiles.third, count: 3 } }
    let(:expected_ids) { [ 2, 3, 4 ] }

    it_behaves_like 'success'
  end

  context 'when `giving_board` is true' do
    let(:args) { { team:, giving_board: true } }
    let(:expected_ids) { [ 3, 4, 5 ] }

    it_behaves_like 'success'
  end

  context 'when `jab_board` is true' do
    let(:args) { { team:, jab_board: true } }
    let(:expected_ids) { [ 4, 3, 5 ] }

    it_behaves_like 'success'
  end

  context 'when offset is given (paging)' do
    let(:args) { { team:, count: 3, offset: 1 } }
    let(:expected_ids) { [ 2, 3, 4 ] }

    it_behaves_like 'success'
  end
end
