require 'rails_helper'

describe Hooks::Slack::EventsController do
  include Rack::Test::Methods

  subject(:response) { post(hooks_slack_command_path) }

  include_context 'with active team' do
    let(:team) { create(:team) }
  end

  before do
    allow(EventWorker).to receive(:perform_async)
  end

  it 'calls Slack::PostService and EventWorker' do
    expect(response).to be_ok
    expect(EventWorker).to have_received(:perform_async)
  end
end
