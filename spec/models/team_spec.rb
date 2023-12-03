require 'rails_helper'

RSpec.describe Team do
  subject(:team) { create(:team) }

  it { is_expected.to be_a(ApplicationRecord) }
  it { is_expected.to be_a(Sluggi::Slugged) }

  it do
    expect(team)
      .to belong_to(:owner)
      .class_name('Profile').with_foreign_key(:owner_profile_id).inverse_of(:owned_team).optional
  end

  it { is_expected.to have_many(:channels).dependent(:destroy) }
  it { is_expected.to have_many(:profiles).dependent(:destroy) }
  it { is_expected.to have_many(:subteams).dependent(:destroy) }
  it { is_expected.to have_many(:topics).dependent(:destroy) }
  it { is_expected.to have_many(:rewards).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:platform) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:rid) }
  it { is_expected.to validate_uniqueness_of(:rid) }
  it { is_expected.to validate_uniqueness_of(:api_key) }
  it { is_expected.to validate_presence_of(:avatar_url) }
  it { is_expected.to validate_numericality_of(:throttle_quantity).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:throttle_quantity)
      .is_less_than_or_equal_to(App.max_throttle_quantity)
  end

  it { is_expected.to validate_numericality_of(:max_points_per_tip).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:max_points_per_tip)
      .is_less_than_or_equal_to(App.max_points_per_tip)
  end

  it { is_expected.to validate_numericality_of(:max_level).is_greater_than_or_equal_to(10) }
  it { is_expected.to validate_numericality_of(:max_level).is_less_than_or_equal_to(99) }
  it { is_expected.to validate_numericality_of(:max_level_points).is_greater_than_or_equal_to(100) }
  it { is_expected.to validate_numericality_of(:max_level_points).is_less_than_or_equal_to(10_000) }

  it do
    expect(team)
      .to validate_numericality_of(:streak_duration)
      .is_greater_than_or_equal_to(App.min_streak_duration)
  end

  it do
    expect(team)
      .to validate_numericality_of(:streak_duration)
      .is_less_than_or_equal_to(App.max_streak_duration)
  end

  it { is_expected.to validate_numericality_of(:streak_reward).is_greater_than_or_equal_to(1) }

  it do
    expect(team)
      .to validate_numericality_of(:streak_reward)
      .is_less_than_or_equal_to(App.max_streak_reward)
  end

  describe 'custom validators' do
    let(:validators) { described_class.validators.map(&:class) }
    let(:expected_validators) do
      [
        RequireTopicValidator,
        WorkDaysValidator
      ]
    end

    it 'validates with expected validators' do
      expect(validators).to include(*expected_validators)
    end
  end

  it 'sets default work_days' do
    expect(team.work_days).to eq(%w[monday tuesday wednesday thursday friday])
  end

  context 'when becoming oversized' do
    let(:slack_client) { instance_spy(Slack::Web::Client) }

    before do
      allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
      allow(slack_client).to receive(:apps_uninstall)
    end

    xit 'sets active to false if team gets oversized during trial subscription' do
      team.update(member_count: App.max_team_size + 1)
      expect(team.reload.active?).to be(false)
    end
  end

  describe '#oversized?' do
    it 'returns true if exceeding App.max_team_size' do
      team.member_count = 10_000
      expect(team.oversized?).to be(true)
    end
  end

  describe '#active scope' do
    let(:active_team) { create(:team) }

    before { create(:team, uninstalled_at: Time.current) }

    it 'returns only active teams' do
      expect(described_class.active).to eq([active_team])
    end
  end

  describe '#trial_expired scope' do
    let(:expired_team) { create(:team, trial_expires_at: 120.days.ago) }

    before { create(:team, trial_expires_at: 120.days.from_now) }

    it 'returns only expired teams' do
      expect(described_class.trial_expired).to eq([expired_team])
    end
  end

  describe '#subscribed_at_least_once scope' do
    let(:subscribed_team) { create(:team, stripe_expires_at: Time.current) }

    before { create(:team, stripe_expires_at: nil) }

    it 'returns only teams that have subscribed at least once' do
      expect(described_class.subscribed_at_least_once).to eq([subscribed_team])
    end
  end

  describe '#never_subscribed scope' do
    let(:never_subscribed_team) { create(:team, stripe_expires_at: nil) }

    before { create(:team, stripe_expires_at: Time.current) }

    it 'returns only not teams that have never subscribed' do
      expect(described_class.never_subscribed).to eq([never_subscribed_team])
    end
  end

  describe '#gratis scope' do
    let(:gratis_team) { create(:team, gratis_subscription: true) }

    before { create(:team, gratis_subscription: false) }

    it 'returns only gratis teams' do
      expect(described_class.gratis).to eq([gratis_team])
    end
  end

  describe '#non_gratis scope' do
    let(:non_gratis_team) { create(:team, gratis_subscription: false) }

    before { create(:team, gratis_subscription: true) }

    it 'returns only non-gratis teams' do
      expect(described_class.non_gratis).to eq([non_gratis_team])
    end
  end

  describe 'slug' do
    subject(:team) { create(:team, name:) }

    let(:name) { 'My Team' }

    it 'creates the slug from parameterized name' do
      expect(team.slug).to eq('my-team')
    end

    context 'with a name that produces a conflicting slug' do
      before { create(:team, name:) }

      it 'creates the slug from parameterized name with random suffix' do
        expect(team.slug).to match(/my-team-[a-f0-9]{6}/)
      end
    end
  end

  describe 'work days=' do
    before { team.work_days = %w[monday tuesday wednesday] }

    it 'stores days as bitmask in work_days_mask' do
      expect(team.work_days_mask).to eq(14)
    end
  end

  describe 'work days' do
    before { team.work_days_mask = 71 }

    it 'provides work_days=' do
      expect(team.work_days).to eq(%w[sunday monday tuesday saturday])
    end
  end

  describe 'app_profile' do
    let!(:profile) { create(:profile, team:, rid: team.app_profile_rid) }

    it 'returns the expected profile' do
      expect(team.app_profile).to eq(profile)
    end
  end

  describe '#uninstall!' do
    let(:slack_client) { instance_spy(Slack::Web::Client) }

    before do
      allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
      allow(slack_client).to receive(:apps_uninstall)
      team.uninstall!('Test')
    end

    it 'calls Slack::Web::Client#apps_uninstall' do
      expect(slack_client).to have_received(:apps_uninstall).with \
        client_id: App.slack_client_id,
        client_secret: App.slack_client_secret
      expect(team.reload.inactive?).to be(true)
    end
  end

  describe 'joins log_channel on change (Slack only)' do
    let(:channel) { create(:channel, team:) }

    before do
      allow(Slack::ChannelJoinService).to receive(:call)
      team.update(platform: :slack, log_channel_rid: channel.rid)
    end

    it 'calls Slack::ChannelJoinService' do
      expect(Slack::ChannelJoinService)
        .to have_received(:call).with(team:, channel_rid: channel.rid)
    end
  end

  xdescribe 'sync_topic_attrs' do
  end
end
