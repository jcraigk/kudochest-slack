require 'rails_helper'
require 'ostruct'

RSpec.describe TipMentionService, :freeze_time do
  subject(:service) { described_class.call(**opts) }

  let(:team) do
    create(:team, split_tip: false)
  end
  let(:channel) { create(:channel, team:) }
  let(:profile) { create(:profile, team:) }
  let(:to_profile) { create(:profile, team:) }
  let(:mentions) { [ Mention.new(rid: "#{PROF_PREFIX}#{to_profile.rid}", quantity: 1) ] }
  let(:note) { 'A note!' }
  let(:ts) { Time.current.to_f.to_s }
  let(:timestamp) { Time.current }
  let(:opts) do
    {
      channel_name: channel.name,
      channel_rid: channel.rid,
      event_ts: ts,
      message_ts: ts,
      mentions:,
      note:,
      profile:,
      source: 'inline',
      timestamp:
    }
  end

  shared_examples 'expected result' do
    it 'returns expected result' do
      expect(service).to eq(result)
    end
  end

  before do
    travel_to(Time.zone.local(2019, 11, 10, 21, 1, 1))
    allow(team.slack_client).to \
      receive(:chat_getPermalink).and_return(OpenStruct.new(permalink: 'link'))
  end

  context 'when `profile.announce_tip_sent `is false`' do
    let(:result) { ChatResponse.new(mode: :silent) }

    before do
      profile.update(announce_tip_sent: false)
    end

    it_behaves_like 'expected result'
  end

  context 'when sender has exceeded throttle limit' do
    let(:text) do
      <<~TEXT.squish
        :#{App.error_emoji}: Sorry #{profile.link}, you must wait 1 day to give more #{App.points_term}
      TEXT
    end
    let(:result) { ChatResponse.new(mode: :error, text:) }

    before do
      team.update(throttled: true, throttle_period: 'day', throttle_quantity: 1)
      create(:tip, from_profile: profile)
    end

    it_behaves_like 'expected result'
  end

  context 'when required note is missing' do
    let(:note) { '' }
    let(:text) { I18n.t('tips.note_required') }
    let(:result) { ChatResponse.new(mode: :error, text:) }

    before do
      team.tip_notes = 'required'
    end

    it_behaves_like 'expected result'
  end

  context 'when no mentions are provided' do
    let(:mentions) { [] }
    let(:result) do
      ChatResponse.new(mode: :error, text: I18n.t('errors.no_tips', user: profile.display_name))
    end

    it_behaves_like 'expected result'
  end

  xcontext 'when `@everyone` is mentioned' do
    let(:mentions) { [ 'everyone' ] }

    xit 'overrides other mentions' do
    end
  end

  xcontext 'when `@here` is mentioned' do
    let(:mentions) { [ 'here' ] }

    xit 'overrides other mentions' do
    end
  end

  xcontext 'when team.split_tip is true' do
  end

  context 'when mixture of valid mentions are provided' do
    let(:mentions) do
      [
        Mention.new(rid: "#{PROF_PREFIX}#{to_profile.rid}", quantity: 1, topic_id: nil),
        Mention.new(rid: "#{CHAN_PREFIX}#{channel.rid}", quantity: 1, topic_id: nil),
        Mention.new(rid: "#{SUBTEAM_PREFIX}#{subteam.rid}", quantity: 1, topic_id: nil)
      ]
    end
    let(:result) do
      ChatResponse.new \
        mode: :public,
        response: tip_response,
        tips: Tip.all,
        image: nil
    end
    let(:tip_response) { 'A mock tip response' }
    let(:mention_entities) do
      [
        EntityMention.new(entity: to_profile, profiles: [ to_profile ]),
        EntityMention.new(entity: subteam, profiles: [ subteam_profile, other_profile ]),
        EntityMention.new(entity: channel, profiles: [ channel_profile ])
      ]
    end
    let(:subteam) { create(:subteam, team:) }
    let(:subteam_profile) { create(:profile, team:) }
    let(:channel_profile) { create(:profile, team:) }
    let(:base_tip_attrs) do
      {
        event_ts: ts,
        message_ts: ts,
        from_channel_name: channel.name,
        from_channel_rid: channel.rid,
        from_profile: profile,
        note:,
        quantity: 1,
        topic_id: nil,
        source: 'inline',
        timestamp:
      }
    end
    let(:other_profile) { create(:profile, team:) }

    before do
      subteam.profiles << [ subteam_profile, to_profile, other_profile ]
      allow(TipResponseService).to receive(:call).and_return(tip_response)
      allow(Slack::ChannelMemberService)
        .to receive(:call).and_return([ channel_profile, other_profile ])
      service
    end

      it 'creates tips for unique profiles, favoring direct, then subteam, then channel' do
      expect(Tip.count).to eq(4)

      tip_recipients = Tip.pluck(:to_profile_id)
      expect(tip_recipients).to contain_exactly(
        to_profile.id,        # Direct mention
        subteam_profile.id,   # From subteam
        other_profile.id,     # From subteam (not deduplicated from channel)
        channel_profile.id    # From channel
      )

      expect(Tip.find_by(to_profile: to_profile).to_subteam_rid).to be_nil
      expect(Tip.find_by(to_profile: subteam_profile).to_subteam_rid).to eq(subteam.rid)
      expect(Tip.find_by(to_profile: other_profile).to_subteam_rid).to eq(subteam.rid)
      expect(Tip.find_by(to_profile: channel_profile).to_channel_rid).to eq(channel.rid)
    end
  end
end
