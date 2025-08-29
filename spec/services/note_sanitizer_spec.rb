require 'rails_helper'

RSpec.describe NoteSanitizer do
  subject(:service) { described_class.call(team_rid: team.rid, text:) }

  let(:team) { create(:team) }
  let(:subteam) { create(:subteam, team:) }
  let(:profile) { create(:profile, team:) }
  let(:channel) { create(:channel, team:) }

  shared_examples 'success' do
    it 'sanitizes mentions' do
      expect(service).to eq(result)
    end
  end

  context 'when special chars are included' do
    let(:text) { 'hey &lt; &gt; &amp; *' }
    let(:result) { 'hey < > &' }

    it_behaves_like 'success'
  end

  context 'when Slack' do
    context 'when channel name is given after pipe char, extacts directly' do
      let(:given_name) { 'given-name' }
      let(:text) { "hey <#{App.chan_prefix}#{channel.rid}|#{given_name}>" }
      let(:result) { "hey #{App.chan_prefix}#{given_name}" }

      it_behaves_like 'success'
    end

    context 'when profile display_name name is given after pipe char, extacts directly' do
      let(:given_name) { 'given-name' }
      let(:text) { "hey <#{App.prof_prefix}#{profile.rid}|#{given_name}>" }
      let(:result) { "hey #{App.prof_prefix}#{given_name}" }

      it_behaves_like 'success'
    end

    context 'when url given, extacts' do
      let(:link_name) { 'This is a link' }
      let(:text) { "hey <https://www.google.com|#{link_name}>" }
      let(:result) { "hey #{link_name}" }

      it_behaves_like 'success'
    end

    context 'when no names given after pipe char' do
      let(:text) do
        <<~TEXT
          hey <#{App.subteam_prefix}#{subteam.rid}> yep <#{App.chan_prefix}#{channel.rid}> and <#{App.prof_prefix}#{profile.rid}> with <http://google.com|google.com>
        TEXT
      end
      let(:result) do
        <<~TEXT.squish
          hey #{App.prof_prefix}#{subteam.handle} yep #{App.chan_prefix}#{channel.name} and #{App.prof_prefix}#{profile.display_name} with google.com
        TEXT
      end

      it_behaves_like 'success'
    end
  end
end
