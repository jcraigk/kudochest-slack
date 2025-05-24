require 'rails_helper'

RSpec.describe Slack::ChannelMemberService do
  let(:slack_client) { instance_spy(Slack::Web::Client) }
  let(:channels_data) { { members: team.profiles.map(&:rid) } }

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(slack_client).to receive(:conversations_members).and_return(channels_data)
  end

  it_behaves_like 'ChannelMemberService'
end
