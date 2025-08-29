require 'rails_helper'

RSpec.describe ProfileDecorator do
  subject(:profile) { build(:profile) }

  # TODO: Rename this to "mention"
  describe '#link' do
    it 'returns expected text' do
      expect(profile.link).to eq("<#{App.prof_prefix}#{profile.rid}>")
    end
  end

  describe '#link_with_stat' do
    subject(:profile) { build(:profile, team:) }

    let(:team) { build(:team) }

    context 'when team.enable_levels is true' do
      before { team.enable_levels = true }

      it 'returns expected text' do
        expect(profile.link_with_stat).to eq(profile.link_with_level)
      end
    end

    context 'when team.enable_levels is false' do
      before { team.enable_levels = false }

      it 'returns expected text' do
        expect(profile.link_with_stat).to eq(profile.link_with_points(label: false))
      end
    end
  end

  describe '#link_with_level' do
    subject(:profile) { build(:profile) }

    let(:expected_text) { "<#{App.prof_prefix}#{profile.rid}> (level 1)" }

    it 'returns expected text' do
      expect(profile.link_with_level).to eq(expected_text)
    end
  end

  describe '#link_with_points' do
    let(:text) { "#{profile.link} (#{points_format(2_678, label: true)})" }

    before { profile.balance = 2_678 }

    it 'returns expected text' do
      expect(profile.link_with_points).to eq(text)
    end
  end

  describe '#profile_link' do
    it 'returns expected text' do
      expect(profile.dashboard_link).to \
        eq("<#{App.base_url}/profiles/#{profile.slug}|#{profile.display_name}>")
    end
  end

  describe '#webref' do
    it 'returns expected text' do
      expect(profile.webref)
        .to eq("<span class=\"chat-ref\">#{profile.display_name}</span>")
    end
  end

  describe '#webref_with_stat' do
    subject(:profile) { build(:profile, team:) }

    let(:team) { build(:team) }

    context 'when team.enable_levels is true' do
      before { team.enable_levels = true }

      it 'returns expected text' do
        expect(profile.webref_with_stat).to eq(profile.webref_with_level)
      end
    end

    context 'when team.enable_levels is false' do
      before { team.enable_levels = false }

      it 'returns expected text' do
        expect(profile.webref_with_stat).to eq(profile.webref_with_points)
      end
    end
  end

  describe '#webref_with_level' do
    subject(:profile) { build(:profile) }

    let(:expected_text) { "#{profile.webref} (level 1)" }

    it 'returns expected text' do
      expect(profile.webref_with_level).to eq(expected_text)
    end
  end

  describe '#webref_with_points' do
    let(:text) { "#{profile.webref} (#{points_format(2_678, label: true)})" }

    before { profile.balance = 2_678 }

    it 'returns expected text' do
      expect(profile.webref_with_points).to eq(text)
    end
  end

  describe '#long_name' do
    it 'returns expected text' do
      expect(profile.long_name)
        .to eq("#{profile.display_name} (#{profile.real_name})")
    end
  end

  describe '#next_level_points_sentence' do
    subject(:profile) { build(:profile, team:, balance: 359) }

    let(:team) { build(:team, max_level: 10, max_level_points: 450, level_curve: :steep) }
    let(:expected_text) { "#{points_format(91, label: true)} until level 10" }

    it 'returns expected text' do
      expect(profile.next_level_points_sentence).to eq(expected_text)
    end
  end

  describe '#points_remaining_until_next_level' do
    context 'when profile is at max level' do
      before { profile.update(balance: profile.team.max_level_points) }

      it 'returns 0' do
        expect(profile.points_remaining_until_next_level).to eq(0)
      end
    end

    context 'when profile is below max level' do
      before { profile.update(balance: 26) }

      it 'returns points quantity' do
        expect(profile.points_remaining_until_next_level).to eq(9)
      end
    end
  end

  describe '#level' do
    before { allow(PointsToLevelService).to receive(:call) }

    it 'calls PointsToLevelService' do
      profile.level
      expect(PointsToLevelService).to have_received(:call).with \
        team: profile.team, points: profile.points
    end
  end

  describe '#next_level' do
    context 'when profile is at max level' do
      before { profile.update(balance: profile.team.max_level_points) }

      it 'returns max_level' do
        expect(profile.next_level).to eq(profile.team.max_level)
      end
    end

    context 'when profile is below max level' do
      before { profile.update(balance: 26) }

      it 'returns points quantity' do
        expect(profile.next_level).to eq(3)
      end
    end
  end

  describe '#max_level?' do
    context 'when profile is at max level' do
      before { profile.update(balance: profile.team.max_level_points) }

      it 'returns true' do
        expect(profile.max_level?).to be(true)
      end
    end

    context 'when profile is below max level' do
      before { profile.update(balance: 26) }

      it 'returns false' do
        expect(profile.max_level?).to be(false)
      end
    end
  end

  describe '#active_streak' do
    shared_examples 'expected result' do
      before { profile.streak_date = streak_date }

      it 'returns expected integer' do
        expect(profile.active_streak).to eq(result)
      end
    end

    before { profile.streak_count = 2 }

    context 'when current day is a workday' do
      before { travel_to(Time.zone.local(2019, 11, 11, 21, 1, 1)) } # Monday

      context 'when no streak_date set' do
        let(:result) { 0 }
        let(:streak_date) { nil }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is today' do
        let(:result) { 2 }
        let(:streak_date) { Time.zone.local(2019, 11, 11, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is previous working day' do
        let(:result) { 2 }
        let(:streak_date) { Time.zone.local(2019, 11, 8, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is in the distant past' do
        let(:result) { 0 }
        let(:streak_date) { Time.zone.local(2019, 10, 1, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is tomorrow' do
        let(:result) { 2 }
        let(:streak_date) { Time.zone.local(2019, 11, 12, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end

      xcontext 'when today is next streak date' do
      end

      xcontext 'when streak date is in future not torrow (after weekend)' do
      end
    end

    context 'when current day is not a workday' do
      before { travel_to(Time.zone.local(2019, 11, 10, 21, 1, 1)) } # Sunday

      context 'when no streak_date set' do
        let(:result) { 0 }
        let(:streak_date) { nil }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is today' do
        let(:result) { 2 }
        let(:streak_date) { Time.zone.local(2019, 11, 10, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is in the distant past' do
        let(:result) { 0 }
        let(:streak_date) { Time.zone.local(2019, 10, 1, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end

      context 'when streak_date is tomorrow' do
        let(:result) { 2 }
        let(:streak_date) { Time.zone.local(2019, 11, 11, 21, 1, 1).to_date }

        it_behaves_like 'expected result'
      end
    end
  end

  describe '#active_streak_sentence' do
    before { travel_to(Time.zone.local(2019, 11, 11, 21, 1, 1)) } # Monday

    context 'with no active streak' do
      let(:result) { '0 days' }

      before do
        profile.streak_date = nil
        profile.streak_count = 0
      end

      it 'returns expected sentence' do
        expect(profile.active_streak_sentence).to eq(result)
      end
    end

    context 'with an active streak' do
      let(:result) { '2 days, next target Nov 12 (tomorrow)' }

      before do
        profile.streak_date = Time.zone.local(2019, 11, 11, 21, 1, 1).to_date
        profile.streak_count = 2
      end

      it 'returns expected sentence' do
        expect(profile.active_streak_sentence).to eq(result)
      end
    end
  end
end
