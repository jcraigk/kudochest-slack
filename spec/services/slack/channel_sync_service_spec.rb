require 'rails_helper'

RSpec.describe Slack::ChannelSyncService, vcr: { cassette_name: 'slack/channel_service' } do
  let(:new_channel_rid) { 'C0103NCM3L2' } # `bot` channel

  include_examples 'ChannelSyncService' # rubocop:disable RSpec/IncludeExamples

  it 'joins new channel' do
    expect(Slack::ChannelJoinService)
      .to have_received(:call).with(team:, channel_rid: new_channel_rid)
  end

  context 'with shared channels' do
    let(:team) { create(:team, api_key: 'api-key') }
    let(:shared_channels) do
      [
        { id: 'C1', name: 'shared-channel', is_shared: true, is_org_shared: false, is_ext_shared: false, num_members: 10 },
        { id: 'C2', name: 'org-shared-channel', is_shared: false, is_org_shared: true, is_ext_shared: false, num_members: 10 },
        { id: 'C3', name: 'ext-shared-channel', is_shared: false, is_org_shared: false, is_ext_shared: true, num_members: 10 },
        { id: 'C4', name: 'local-channel', is_shared: false, is_org_shared: false, is_ext_shared: false, num_members: 10 }
      ]
    end

    before do
      allow(team).to receive(:slack_client).and_return(double(conversations_list: { channels: shared_channels }))
      described_class.call(team:)
    end

    it 'filters out shared channels' do
      expect(team.channels.pluck(:rid)).not_to include('C1')
    end

    it 'filters out org shared channels' do
      expect(team.channels.pluck(:rid)).not_to include('C2')
    end

    it 'filters out externally shared channels' do
      expect(team.channels.pluck(:rid)).not_to include('C3')
    end

    it 'includes local channels' do
      expect(team.channels.pluck(:rid)).to include('C4')
    end

    it 'creates only local channels' do
      expect(team.channels.count).to eq(1)
      expect(team.channels.first.name).to eq('local-channel')
    end
  end
end
