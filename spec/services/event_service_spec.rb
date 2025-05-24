require 'rails_helper'

RSpec.describe EventService do
  subject(:service) { described_class.call(params:) }

  let(:params) do
    {
      platform: 'slack',
      action: 'message',
      channel_rid: 'C012345'
    }
  end

  shared_examples 'success' do
    it 'calls Slack::PostService with expected args' do
      service
      expect(Slack::PostService).to have_received(:call).with(args)
    end
  end

  before do
    allow(Slack::PostService).to receive(:call)
  end

  context 'when an exception occurs and channel_rid is present' do
    let(:text) { ":#{App.error_emoji}: #{I18n.t('slack.generic_error')}" }
    let(:args) { params.merge(mode: :error, text:) }

    before { allow(Actions::Message).to receive(:call).and_raise('whoopsy') }

    it_behaves_like 'success'
  end

  context 'without exception' do
    let(:args) { params.merge(result.to_h) }
    let(:result) { ChatResponse.new(mode: :public) }

    before { allow(Actions::Message).to receive(:call).and_return(result) }

    it_behaves_like 'success'
  end
end
