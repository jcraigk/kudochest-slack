require 'rails_helper'

RSpec.describe MentionParser do
  subject(:service) { described_class.call(**opts) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:to_profile) { create(:profile, team:) }
  let(:to_profile2) { create(:profile, team:) }
  let(:channel) { create(:channel, team:) }
  let(:channel_name) { channel.name }
  let(:quantity) { 2 }
  let(:quantity2) { 2 }
  let(:note) { 'and here is a note' }
  let(:ts) { Time.current.to_f.to_s }
  let(:matches) do
    [
      {
        rid: to_profile.rid,
        inline: '++',
        suffix_quantity: 2,
        note:
      },
      {
        rid: to_profile2.rid,
        inline: '++',
        prefix_quantity: quantity2
      }
    ]
  end
  let(:opts) do
    {
      team_rid: team.rid,
      profile_rid: profile.rid,
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name:,
      matches:
    }
  end
  let(:tip_mention_args) do
    {
      profile:,
      mentions:,
      source: 'inline',
      event_ts: ts,
      channel_rid: channel.rid,
      channel_name:
    }
  end
  let(:mentions) do
    [
      Mention.new(
        rid: to_profile.rid,
        quantity:,
        note:
      ),
      Mention.new(
        rid: to_profile2.rid,
        quantity: quantity2
      )
    ]
  end

  before do
    allow(TipMentionService).to receive(:call)
    service
  end

  it 'calls TipMentionService' do
    expect(TipMentionService).to have_received(:call).with(tip_mention_args)
  end

  xcontext 'when topic emoji is given' do
    # TODO: @Alice ++2 :fire:
    # TODO: @Alice :fire: :fire:
  end

  context 'with default inline point quantities' do
    let(:team) { create(:team, default_inline_quantity: 3) }

    context 'when using ++ without explicit quantity' do
      let(:matches) do
        [
          {
            rid: to_profile.rid,
            inline_text: '++',
            inline: '++'
          }
        ]
      end
      let(:mentions) do
        [
          Mention.new(
            rid: to_profile.rid,
            quantity: 3,
            note: nil
          )
        ]
      end

      it 'uses the team default quantity' do
        expect(TipMentionService).to have_received(:call).with(tip_mention_args)
      end
    end

    context 'when using -- without explicit quantity (jabs)' do
      let(:matches) do
        [
          {
            rid: to_profile.rid,
            inline_text: '--',
            inline: '--'
          }
        ]
      end
      let(:mentions) do
        [
          Mention.new(
            rid: to_profile.rid,
            quantity: -3,
            note: nil
          )
        ]
      end

      it 'uses negative team default quantity for jabs' do
        expect(TipMentionService).to have_received(:call).with(tip_mention_args)
      end
    end

    context 'when explicit quantity is provided' do
      let(:matches) do
        [
          {
            rid: to_profile.rid,
            inline_text: '++',
            inline: '++',
            prefix_quantity: '5'
          }
        ]
      end
      let(:mentions) do
        [
          Mention.new(
            rid: to_profile.rid,
            quantity: 5,
            note: nil
          )
        ]
      end

      it 'uses explicit quantity over default' do
        expect(TipMentionService).to have_received(:call).with(tip_mention_args)
      end
    end

    context 'with single emoji and no explicit quantity' do
      let(:team) { create(:team, default_inline_quantity: 2, enable_emoji: true, point_emoji: 'fire') }
      let(:matches) do
        [
          {
            rid: to_profile.rid,
            inline_emoji: ':fire:'
          }
        ]
      end
      let(:mentions) do
        [
          Mention.new(
            rid: to_profile.rid,
            quantity: 2,
            note: nil
          )
        ]
      end

      it 'uses team default quantity for single emoji' do
        expect(TipMentionService).to have_received(:call).with(tip_mention_args)
      end
    end

    context 'with multiple emoji instances' do
      let(:team) { create(:team, default_inline_quantity: 2, enable_emoji: true, point_emoji: 'fire') }
      let(:matches) do
        [
          {
            rid: to_profile.rid,
            inline_emoji: ':fire::fire::fire:'
          }
        ]
      end
      let(:mentions) do
        [
          Mention.new(
            rid: to_profile.rid,
            quantity: 3,
            note: nil
          )
        ]
      end

      it 'uses emoji count as quantity' do
        expect(TipMentionService).to have_received(:call).with(tip_mention_args)
      end
    end

    context 'with emoji and explicit quantity' do
      let(:team) { create(:team, default_inline_quantity: 2, enable_emoji: true, point_emoji: 'fire') }
      let(:matches) do
        [
          {
            rid: to_profile.rid,
            inline_emoji: ':fire:',
            prefix_quantity: '4'
          }
        ]
      end
      let(:mentions) do
        [
          Mention.new(
            rid: to_profile.rid,
            quantity: 4,
            note: nil
          )
        ]
      end

      it 'uses explicit quantity over default' do
        expect(TipMentionService).to have_received(:call).with(tip_mention_args)
      end
    end
  end
end
