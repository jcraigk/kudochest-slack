require 'rails_helper'

RSpec.describe TeamRegistrar, :freeze_time do
  subject(:service) { described_class.call(**opts) }

  let(:profile) { create(:profile) }
  let(:opts) do
    {
      platform: :slack,
      rid: team.rid,
      name: team.name,
      api_key: team.api_key,
      owner_profile_rid: profile.rid,
      avatar_url: 'url230'
    }
  end
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:team_attrs) do
    {
      platform: :slack,
      trial_expires_at: App.trial_period.from_now,
      response_mode: :adaptive,
      rid: team.rid,
      name: team.name,
      api_key: team.api_key,
      avatar_url: 'url230',
      uninstalled_at: nil,
      uninstalled_by: nil
    }
  end

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(Slack::ChannelSyncService).to receive(:call)
    allow(Slack::TeamSyncService).to receive(:call)
  end

  context 'when no team with RID exists' do
    let(:team) { build(:team) }
    let(:mock_mailer) { instance_spy(ActionMailer::MessageDelivery) }

    before do
      allow(Team).to receive(:create!).and_return(team)
      service
    end

    it 'creates a Team and calls sync services' do
      expect(Team).to have_received(:create!).with(team_attrs)
      expect(Slack::ChannelSyncService).to have_received(:call).with(team:)
      expect(Slack::TeamSyncService).to have_received(:call).with(team:, first_run: true)
      expect(team.reload.owner).to eq(profile)
    end
  end

  context 'when team with RID exists' do
    let!(:team) { create(:team) }

    before do
      allow(Team).to receive(:find_by).with({ rid: team.rid }).and_return(team)
      allow(team).to receive(:update!)
      service
    end

    it 'updates existing team and calls sync workers' do
      expect(team).to have_received(:update!).twice
      expect(Slack::ChannelSyncService).to have_received(:call).with(team:)
      expect(Slack::TeamSyncService).to have_received(:call).with(team:, first_run: true)
    end
  end
end
