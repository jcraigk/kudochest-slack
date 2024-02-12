require 'rails_helper'

RSpec.describe MessageScanner do
  subject(:call) { described_class.call(text:, regex: Regexp.new(team.config[:regex])) }

  let(:team) { create(:team) }
  let(:matches) { [] }
  let(:text) { '' }
  let(:note) { 'way to go' }
  let(:note2) { 'thank you' }
  let(:rid1) { '@UNNW3U043' }
  let(:rid2) { '@UNNW3U044' }

  shared_examples 'success' do
    it 'returns expected matches' do
      expect(call).to eq(matches)
    end
  end

  context 'with repeated `++` groups' do
    let(:text) { "<#{rid1}>++++++" }
    let(:matches) do
      [
        {
          rid: rid1,
          inline_text: '++++++',
          prefix_quantity: 3
        }
      ]
    end

    include_examples 'success'
  end

  context 'with `+3`' do
    let(:text) { "<#{rid1}> +3" }
    let(:matches) do
      [
        {
          rid: rid1,
          inline_text: '+',
          suffix_quantity: 3
        }
      ]
    end

    include_examples 'success'
  end

  context 'with repeated profile, repeated `++`, and notes' do
    let(:text) { "<#{rid1}>++++ <#{rid1}>++" }
    let(:matches) do
      [
        {
          rid: rid1,
          inline_text: '++++',
          prefix_quantity: 2
        },
        {
          rid: rid1,
          inline_text: '++'
        }
      ]
    end

    include_examples 'success'
  end

  context 'with topic keywords and single trailing note' do
    let!(:topic1) { create(:topic, team:) }
    let!(:topic2) { create(:topic, team:) }
    let(:text) { "<#{rid1}>++2 #{topic1.keyword} <#{rid2}> 3-- #{topic2.keyword} #{note}" }
    let(:matches) do
      [
        {
          rid: rid1,
          inline_text: '++',
          suffix_quantity: 2,
          topic_keyword: topic1.keyword,
          note:
        },
        {
          rid: rid2,
          prefix_quantity: 3,
          inline_text: '--',
          topic_keyword: topic2.keyword,
          note:
        }
      ]
    end

    include_examples 'success'
  end

  context 'with inline emoji and personalized notes' do
    let(:text) do
      "<#{rid1}> #{team.point_emoj} #{team.point_emoj} #{note} " \
        "<#{rid2}>#{team.jab_emoj} #{note2}"
    end
    let(:matches) do
      [
        {
          rid: rid1,
          inline_emoji: "#{team.point_emoj}#{team.point_emoj}",
          note:
        },
        {
          rid: rid2,
          inline_emoji: team.jab_emoj,
          note: note2
        }
      ]
    end

    include_examples 'success'
  end
end
