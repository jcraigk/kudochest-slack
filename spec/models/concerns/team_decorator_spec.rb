require 'rails_helper'

RSpec.describe TeamDecorator do
  subject(:team) { build(:team) }

  describe '#levels_table' do
    subject(:team) do
      build(:team, max_level: 10, max_level_points: 450, level_curve: :steep)
    end

    let(:expected_text) do
      <<~TEXT.strip
        Level  #{App.points_term.titleize}  Delta
        -----  -----  -----
        1      0      0
        2      5      5
        3      20     15
        4      45     25
        5      82     37
        6      131    49
        7      193    62
        8      266    73
        9      352    86
        10     450    98
      TEXT
    end

    it 'returns expected text' do
      expect(team.levels_table).to eq(expected_text)
    end
  end

  describe 'exempt_profiles_sentence' do
    context 'when no exempt profiles' do
      let(:sentence) { 'None' }

      it 'returns expected sentence' do
        expect(team.exempt_profiles_sentence).to eq(sentence)
      end
    end

    context 'when exempt profiles exist' do
      let!(:profile2) do
        create(:profile, team:, display_name: 'A1', throttle_exempt: true)
      end
      let!(:profile3) do
        create(:profile, team:, display_name: 'B1', throttle_exempt: true)
      end
      let(:sentence) { "#{profile2.link} and #{profile3.link}" }

      before do
        create(:profile, team:) # Throttled profile
      end

      it 'returns expected sentence' do
        expect(team.exempt_profiles_sentence).to eq(sentence)
      end
    end
  end

  describe 'workspace_noun' do
    context 'when slack' do
      before { team.platform = :slack }

      it 'is `workspace`' do
        expect(team.workspace_noun).to eq('workspace')
      end
    end
  end

  describe 'trial?' do
    context 'when subscription is gratis' do
      before { team.gratis_subscription = true }

      it 'is false' do
        expect(team.trial?).to be(false)
      end
    end

    context 'when subscription is paid' do
      before { team.stripe_expires_at = 1.month.from_now }

      it 'is false' do
        expect(team.trial?).to be(false)
      end
    end

    context 'when trial is ongoing' do
      before { team.trial_expires_at = 1.month.from_now }

      it 'is true' do
        expect(team.trial?).to be(true)
      end
    end
  end

  describe 'subscription_plan' do
    context 'when stripe_subscription_rid is blank' do
      before { team.stripe_subscription_rid = nil }

      xit 'is nil', pending: 'This fails on TravisCI for some reason' do
        expect(team.subscription_plan).to be_nil
      end
    end

    context 'when stripe_subscription_rid is current' do
      let(:plan) { App.subscription_plans.first }

      before { team.stripe_price_rid = plan.price_rid }

      it 'refers to the plan' do
        expect(team.subscription_plan).to eq(plan)
      end
    end
  end

  describe 'point_emoj' do
    it 'is the default tip emoji' do
      expect(team.point_emoj).to eq(":#{App.default_point_emoji}:")
    end
  end

  describe 'ditto_emoj' do
    it 'is the default ditto emoji' do
      expect(team.ditto_emoj).to eq(":#{App.default_ditto_emoji}:")
    end
  end
end
