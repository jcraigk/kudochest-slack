require 'rails_helper'

RSpec.describe Slack::Modals::Tip do
  subject(:modal) { described_class.call(team_rid: team.rid) }

  let(:team) { create(:team) }
  let(:config) do
    {
      enable_jabs: false,
      enable_topics: false,
      max_points_per_tip: 5,
      tip_notes: 'optional',
      topics: [],
      default_inline_quantity: team.default_inline_quantity,
      default_reaction_quantity: team.default_reaction_quantity
    }
  end

  before do
    allow(Cache::TeamConfig).to receive(:call).with(team.rid).and_return(config)
  end

  describe 'quantity select initial value' do
    context 'with default inline point quantity of 1' do
      let(:team) { create(:team, default_inline_quantity: 1) }

      it 'sets initial option to 1' do
        quantity_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :quantity }
        initial_value = quantity_block.dig(:element, :initial_option, :value)
        expect(initial_value).to eq('1')
      end
    end

    context 'with custom default inline point quantity' do
      let(:team) { create(:team, default_inline_quantity: 3, max_points_per_tip: 5) }
      let(:config) { super().merge(max_points_per_tip: 5) }

      it 'sets initial option to team default' do
        quantity_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :quantity }
        initial_value = quantity_block.dig(:element, :initial_option, :value)
        initial_text = quantity_block.dig(:element, :initial_option, :text, :text)
        expect(initial_value).to eq('3')
        expect(initial_text).to eq('3')
      end

      it 'includes all quantities up to max_points_per_tip' do
        quantity_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :quantity }
        options = quantity_block.dig(:element, :options)
        expect(options.size).to eq(5)
        expect(options.map { |o| o[:value] }).to eq(%w[1 2 3 4 5])
      end
    end

    context 'with jabs enabled' do
      let(:team) { create(:team, default_inline_quantity: 2, enable_jabs: true, max_points_per_tip: 5) }
      let(:config) { super().merge(enable_jabs: true, max_points_per_tip: 5) }

      it 'includes negative and positive quantities' do
        quantity_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :quantity }
        options = quantity_block.dig(:element, :options)
        expect(options.map { |o| o[:value] }).to eq(%w[-5 -4 -3 -2 -1 1 2 3 4 5])
      end

      it 'sets initial option to team default' do
        quantity_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :quantity }
        initial_value = quantity_block.dig(:element, :initial_option, :value)
        expect(initial_value).to eq('2')
      end
    end
  end

  describe 'modal structure' do
    it 'returns a modal with required fields' do
      expect(modal[:type]).to eq(:modal)
      expect(modal[:callback_id]).to eq(:submit_tip_modal)
      expect(modal[:title][:text]).to include('Give')
      expect(modal[:blocks]).to be_an(Array)
    end

    it 'includes quantity select' do
      quantity_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :quantity }
      expect(quantity_block).to be_present
      expect(quantity_block[:type]).to eq(:input)
      expect(quantity_block.dig(:label, :text)).to eq('Quantity')
    end

    it 'includes recipient multiselect' do
      rid_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :rids }
      expect(rid_block).to be_present
      expect(rid_block[:type]).to eq(:input)
      expect(rid_block.dig(:element, :type)).to eq(:multi_external_select)
    end

    context 'with topics enabled' do
      let(:config) do
        super().merge(
          enable_topics: true,
          topics: [
            { id: '1', name: 'Teamwork' },
            { id: '2', name: 'Innovation' }
          ]
        )
      end

      it 'includes topic select' do
        topic_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :topic_id }
        expect(topic_block).to be_present
        expect(topic_block.dig(:element, :options).size).to eq(3) # 2 topics + "No topic"
      end
    end

    context 'with tip notes enabled' do
      it 'includes note input' do
        note_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :note }
        expect(note_block).to be_present
        expect(note_block[:type]).to eq(:input)
        expect(note_block[:optional]).to be(true)
      end
    end

    context 'with tip notes disabled' do
      let(:config) { super().merge(tip_notes: 'disabled') }

      it 'does not include note input' do
        note_block = modal[:blocks].find { |b| b.dig(:element, :action_id) == :note }
        expect(note_block).to be_nil
      end
    end
  end
end
