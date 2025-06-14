require 'rails_helper'

RSpec.describe Actions::ReactionRemoved do
  subject(:action) { described_class.call(**params) }

  let(:team) { create(:team) }
  let(:sender) { create(:profile, team:) }
  let(:recipient) { create(:profile, team:) }
  let(:ts) { Time.current.to_f }
  let(:params) do
    {
      message_ts: ts,
      profile_rid: sender.rid,
      team_rid: team.rid,
      event: {
        item: {
          ts:
        },
        reaction: emoji
      }
    }
  end
  let(:event_ts) { "#{ts}-#{source}-#{sender.id}" }

  shared_examples 'success' do
    it 'destroys the tip' do
      expect { action }.to change(Tip, :count).by(-1)
    end
  end

  context 'when tip emoji' do
    let(:emoji) { team.point_emoji }
    let(:source) { 'point_reaction' }

    before do
      create(:tip, event_ts:, from_profile: sender)
    end

    it_behaves_like 'success'
  end

  context 'when ditto emoji' do
    let(:emoji) { team.ditto_emoji }
    let(:source) { 'ditto_reaction' }

    before do
      create(:tip, event_ts:, from_profile: sender)
    end

    it_behaves_like 'success'
  end
end
