require 'rails_helper'

RSpec.describe Actions::Message do
  subject(:action) { described_class.call(**params) }

  let(:team) { build(:team, platform:) }
  let(:sender) { create(:profile, team:) }
  let(:profile) { create(:profile, team:) }
  let(:channel) { create(:channel, team:) }
  let(:subteam) { create(:subteam, team:) }
  let(:ts) { Time.current.to_f.to_s }
  let(:note) { 'for being awesome' }
  let(:platform) { :slack }
  let(:params) do
    {
      platform:,
      team_rid: team.rid,
      config: {
        app_profile_rid: team.app_profile_rid
      },
      channel_name: channel.name,
      channel_rid: channel.rid,
      event_ts: ts,
      origin:,
      profile_rid: sender.rid,
      text:,
      matches:
    }
  end
  let(:expected_args) do
    {
      team_rid: team.rid,
      profile_rid: sender.rid,
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name: channel.name,
      matches:
    }
  end
  let(:matches) { [] }
  let(:origin) { 'channel' }
  let(:bot_mention) { "<#{PROFILE_PREFIX[platform]}#{team.app_profile_rid}>" }
  let(:user_mention) { "#{PROFILE_PREFIX[platform]}#{profile.rid}" }

  before do
    allow(MentionParser).to receive(:call)
  end

  shared_examples 'success' do
    it 'calls MentionParser' do
      action
      expect(MentionParser).to have_received(:call).with(expected_args)
    end
  end

  shared_examples 'silence' do
    it 'returns nil' do
      expect(action).to be_nil
    end
  end

  shared_examples 'platform parity' do
    context 'when text does not contain punctuation or bot mention' do
      let(:text) { 'hello world' }

      it_behaves_like 'silence'
    end

    context 'when text is bot mention only' do
      let(:text) { bot_mention }

      it_behaves_like 'silence'
    end

    context 'when text starts with bot mention and contains other text' do
      let(:text) { "#{bot_mention} stats opt1 opt2" }
      let(:command_args) do
        {
          team_rid: team.rid,
          profile_rid: sender.rid,
          text: 'opt1 opt2'
        }
      end

      before { allow(Commands::Stats).to receive(:call) }

      it 'calls Command with opts text' do
        action
        expect(Commands::Stats).to have_received(:call).with(command_args)
      end
    end

    context 'when text includes `++` with user mention' do
      let(:text) { "hello <#{user_mention}> ++ #{note}" }
      let(:matches) do
        [ { rid: user_mention, inline: '++', note: } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes `++2` with user mention' do
      let(:text) { "hello <#{user_mention}> ++2 #{note}" }
      let(:matches) do
        [ { rid: user_mention, inline: '++', suffix_quantity: 2, note: } ]
      end

      it_behaves_like 'success'
    end

    xcontext 'when text include `@everyone++`' do
    end

    context 'when text includes `+=` with valid user' do
      let(:text) { "hello <#{user_mention}> += #{note}" }
      let(:matches) do
        [ { rid: user_mention, inline: '+=', note: } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes single valid inline emoji with valid user' do
      let(:text) { "hello <#{user_mention}> #{team.point_emoj} #{note}" }
      let(:matches) do
        [ { rid: user_mention, inline_emoji: team.point_emoj, note: } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes single valid inline emoji with int suffix' do
      let(:text) { "hello <#{user_mention}> #{team.point_emoj} 2 #{note}" }
      let(:matches) do
        [ { rid: user_mention, inline_emoji: team.point_emoj, suffix_quantity: 2, note: } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes single valid inline emoji with int prefix' do
      let(:text) { "hello <#{user_mention}> 2 #{team.point_emoj} #{note}" }
      let(:matches) do
        [ { rid: user_mention, prefix_quantity: 2, inline_emoji: team.point_emoj, note: } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes multiple valid inline emoji with int suffix' do
      let(:text) do
        <<~TEXT.chomp
          hello <#{user_mention}> #{team.point_emoj} #{team.point_emoj} #{team.point_emoj} 2 #{note}
        TEXT
      end
      let(:matches) do
        [ {
          rid: user_mention,
          inline_emoji: "#{team.point_emoj} #{team.point_emoj} #{team.point_emoj}",
          suffix_quantity: 2,
          note:
        } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes multiple mixed inline emoji with valid user' do
      let(:text) do
        "hello <#{user_mention}> #{team.point_emoj} :invalid_emoji:#{team.point_emoj} #{note}"
      end
      let(:matches) do
        [ {
          rid: user_mention,
          inline_emoji: "#{team.point_emoj} :invalid_emoji:#{team.point_emoj}",
          note:
        } ]
      end

      it_behaves_like 'success'
    end

    context 'when text includes `++` with mixture of entities, spacing, and quantities' do
      let(:text) do
        <<~TEXT.chomp
          hello <#{user_mention}>++ #{subteam_mention} 2+=5 <#{CHAN_PREFIX}#{channel.rid}> ++3 #{note}
        TEXT
      end
      let(:matches) do
        [
          {
            rid: "#{PROFILE_PREFIX[platform]}#{profile.rid}",
            inline: '++'
          },
          {
            rid: "#{SUBTEAM_PREFIX[platform]}#{subteam.rid}",
            prefix_quantity: 2,
            inline: '+=',
            suffix_quantity: 5
          },
          {
            rid: "#{CHAN_PREFIX}#{channel.rid}",
            inline: '++',
            suffix_quantity: 3
          }
        ]
      end

      it_behaves_like 'success'
    end
  end

  context 'when Slack' do
    let(:platform) { :slack }
    let(:subteam_mention) do
      "<#{SUBTEAM_PREFIX[platform]}#{subteam.rid}|#{PROF_PREFIX}#{subteam.handle}>"
    end

    it_behaves_like 'platform parity'

    context 'when command is issued with no keyword' do
      let(:origin) { 'command' }
      let(:text) { '' }

      it 'opens a modal' do
        expect(action).to eq(ChatResponse.new(mode: :tip_modal))
      end
    end
  end
end
