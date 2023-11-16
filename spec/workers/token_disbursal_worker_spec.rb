require 'rails_helper'

RSpec.describe TokenDisbursalWorker do
  subject(:perform) { described_class.new.perform(team.id) }

  let(:team) { create(:team, throttle_tips: true) }

  before do
    allow(Team).to receive(:find).with(team.id).and_return(team)
    allow(TokenDisbursalService).to receive(:call)
    perform
  end

  it 'calls TokenDisbursalService' do
    expect(TokenDisbursalService).to have_received(:call).with(team:)
  end
end
