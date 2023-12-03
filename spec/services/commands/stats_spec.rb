require 'rails_helper'

RSpec.describe Commands::Stats do
  subject(:command) do
    described_class.call(team_rid: team.rid, profile_rid:, text: request_text)
  end

  let(:team) { create(:team, throttled: true, throttle_period: 'week') }
  let(:profile) { create(:profile, team:) }
  let(:profile_rid) { profile.rid }
  let(:response) { ChatResponse.new(mode: :public, text: response_text) }
  let(:leaderboard_data) do
    LeaderboardPage.new(Time.current, [LeaderboardProfile.new(rank:)])
  end
  let(:rank) { 12 }

  shared_examples 'expected response' do
    it 'returns stats text' do
      expect(command).to eq(response)
    end
  end

  before do
    travel_to(Time.zone.local(2023, 11, 8, 21, 1, 1))
    allow(LeaderboardPageService).to receive(:call).and_return(leaderboard_data)
  end

  context 'when no profile given' do
    let(:request_text) { '' }
    let(:response_text) do
      <<~TEXT.chomp
        *Overall Stats for #{profile.dashboard_link}*
        :trophy: *Leaderboard Rank:* ##{rank}
        :crystal_ball: *Level:* 1
        :point_right: *Kudos Received:* 0
        :point_right: *Kudonts Received:* 0
        :scales: *Balance:* 0
        :point_left: *Kudos Given:* 0
        :point_left: *Kudonts Given:* 0
        :stopwatch: *Throttle:* 100 kudos available to give
        :checkered_flag: *Giving Streak:* 0 days
      TEXT
    end

    include_examples 'expected response'

    context 'with throttle_exempt profiles' do
      let(:response_text) do
        <<~TEXT.chomp
          *Overall Stats for #{profile.dashboard_link}*
          :trophy: *Leaderboard Rank:* ##{rank}
          :crystal_ball: *Level:* 1
          :point_right: *Kudos Received:* 0
          :point_right: *Kudonts Received:* 0
          :scales: *Balance:* 0
          :point_left: *Kudos Given:* 0
          :point_left: *Kudonts Given:* 0
          :stopwatch: *Throttle:* Exempt
          :checkered_flag: *Giving Streak:* 0 days
        TEXT
      end

      before { profile.update(throttle_exempt: true) }

      include_examples 'expected response'
    end
  end

  context 'when a profile is given' do
    let(:profile2) { create(:profile, team:) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Overall Stats for #{profile2.dashboard_link}*
        :trophy: *Leaderboard Rank:* ##{rank}
        :crystal_ball: *Level:* 1
        :point_right: *Kudos Received:* 0
        :point_right: *Kudonts Received:* 0
        :scales: *Balance:* 0
        :point_left: *Kudos Given:* 0
        :point_left: *Kudonts Given:* 0
        :checkered_flag: *Giving Streak:* 0 days
      TEXT
    end

    include_examples 'expected response'
  end

  context 'when team.enable_levels is false' do
    let(:profile2) { create(:profile, team:) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Overall Stats for #{profile2.dashboard_link}*
        :trophy: *Leaderboard Rank:* ##{rank}
        :point_right: *Kudos Received:* 0
        :point_right: *Kudonts Received:* 0
        :scales: *Balance:* 0
        :point_left: *Kudos Given:* 0
        :point_left: *Kudonts Given:* 0
        :checkered_flag: *Giving Streak:* 0 days
      TEXT
    end

    before { team.update(enable_levels: false) }

    include_examples 'expected response'
  end

  context 'when team.throttled is false' do
    let(:profile2) { create(:profile, team:) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Overall Stats for #{profile2.dashboard_link}*
        :trophy: *Leaderboard Rank:* ##{rank}
        :crystal_ball: *Level:* 1
        :point_right: *Kudos Received:* 0
        :point_right: *Kudonts Received:* 0
        :scales: *Balance:* 0
        :point_left: *Kudos Given:* 0
        :point_left: *Kudonts Given:* 0
        :checkered_flag: *Giving Streak:* 0 days
      TEXT
    end

    before { team.update(throttled: false) }

    include_examples 'expected response'
  end

  context 'when team.enable_streaks is false' do
    let(:profile2) { create(:profile, team:) }
    let(:request_text) { profile2.link }
    let(:response_text) do
      <<~TEXT.chomp
        *Overall Stats for #{profile2.dashboard_link}*
        :trophy: *Leaderboard Rank:* ##{rank}
        :crystal_ball: *Level:* 1
        :point_right: *Kudos Received:* 0
        :point_right: *Kudonts Received:* 0
        :scales: *Balance:* 0
        :point_left: *Kudos Given:* 0
        :point_left: *Kudonts Given:* 0
      TEXT
    end

    before { team.update(enable_streaks: false) }

    include_examples 'expected response'
  end
end
