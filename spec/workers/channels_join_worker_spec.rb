require 'rails_helper'

RSpec.describe ChannelsJoinWorker do
  subject(:perform) { described_class.new.perform(team.id, channel_rids) }

  let(:team) { create(:team) }
  let!(:channels) { create_list(:channel, 3, team:) }

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(Slack::ChannelJoinService).to receive(:call)
    perform
  end

  context 'with no channel_rids' do
    let(:channel_rids) { [] }

    it 'calls service with expected args (joins all channels)' do
      channel_rids.each do |rid|
        expect(Slack::ChannelJoinService)
          .to have_received(:call).with(team:, channel_rid: rid)
      end
    end
  end

  context 'with channel_rids' do
    let(:channel_rids) { [ channels.first.rid, channels.third.rid ] }

    it 'calls service with expected args (joins specific channels)' do
      channel_rids.each do |rid|
        expect(Slack::ChannelJoinService)
          .to have_received(:call).with(team:, channel_rid: rid)
      end
    end

    it 'does not call service with unexpected args' do
      expect(Slack::ChannelJoinService)
        .not_to have_received(:call).with(team:, channel_rid: channels.second.rid)
    end
  end
end
