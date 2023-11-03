require 'rails_helper'

RSpec.describe SubscriptionExpiryService, :freeze_time do
  subject(:service) { described_class.call }

  let(:slack_client) { instance_spy(Slack::Web::Client) }

  before do
    allow(Slack::Web::Client).to receive(:new).and_return(slack_client)
    allow(slack_client).to receive(:apps_uninstall)
  end

  describe 'team size mismatch warnings' do
    let!(:plan) { App.subscription_plans.first }
    let!(:team_within_range) do
      create(:team, stripe_price_rid: plan.price_rid, member_count: plan.range.begin + 1)
    end
    let!(:team_below_range) do
      create(:team, stripe_price_rid: plan.price_rid, member_count: plan.range.begin - 1)
    end
    let!(:team_above_range) do
      create(:team, stripe_price_rid: plan.price_rid, member_count: plan.range.end + 1)
    end
    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

    before do
      allow(BillingMailer).to \
        receive_messages(team_over_plan: mailer_double, team_under_plan: mailer_double)
      service
    end

    it 'sends warning for teams outside plan range and updates team_size_notified_at' do
      expect(BillingMailer).to have_received(:team_under_plan).with(team_below_range)
      expect(BillingMailer).to have_received(:team_over_plan).with(team_above_range)
      expect(team_below_range.reload.team_size_notified_at).to eq(Time.current)
      expect(team_above_range.reload.team_size_notified_at).to eq(Time.current)
    end

    # TODO: This fails on Travis CI, but not locally
    xit 'does not send warning for teams within plan range' do
      expect(BillingMailer).not_to have_received(:team_under_plan).with(team_within_range)
      expect(BillingMailer).not_to have_received(:team_over_plan).with(team_within_range)
      expect(team_within_range.reload.team_size_notified_at).to be_nil
    end
  end

  describe 'trial expiry warnings' do
    let!(:team_before_warning) do
      create(:team, trial_expires_at: Date.current)
    end
    let!(:team_start_of_warning_period) do
      create(:team, trial_expires_at: 1.day.from_now)
    end
    let!(:team_end_of_warning_period) do
      create(:team, trial_expires_at: SubscriptionExpiryService::WARNING_PERIOD.from_now.to_date)
    end
    let!(:team_after_warning_period) do
      create(:team, trial_expires_at: (SubscriptionExpiryService::WARNING_PERIOD + 1.day).from_now)
    end
    let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }
    let(:meth) { :trial_expires_soon }

    before do
      allow(BillingMailer).to receive(meth).and_return(mailer_double)
      service
    end

    # TODO: This fails on Travis CI, but not locally
    xit 'warns teams in the warning period and updates the trial_expiry_notified_at field' do
      expect(BillingMailer).to have_received(meth).with(team_start_of_warning_period)
      expect(BillingMailer).to have_received(meth).with(team_end_of_warning_period)
      expect(team_start_of_warning_period.reload.trial_expiry_notified_at).to eq(Time.current)
      expect(team_end_of_warning_period.reload.trial_expiry_notified_at).to eq(Time.current)
    end

    it 'does not warn teams outside of the warning period' do
      expect(BillingMailer).not_to have_received(meth).with(team_before_warning)
      expect(BillingMailer).not_to have_received(meth).with(team_after_warning_period)
      expect(team_before_warning.reload.trial_expiry_notified_at).to be_nil
      expect(team_after_warning_period.reload.trial_expiry_notified_at).to be_nil
    end
  end

  describe 'trial expiration' do
    let!(:gratis_team) { create(:team, gratis_subscription: true) }
    let!(:old_team) { create(:team, trial_expires_at: 1.day.ago) }
    let!(:new_team) { create(:team, trial_expires_at: 1.day.from_now) }

    before { service }

    it 'uninstalls the old team' do
      expect(old_team.reload.uninstalled_at).to eq(Time.current)
    end

    it 'does not deactivate other teams' do
      expect(new_team.reload.active?).to be(true)
      expect(gratis_team.reload.active?).to be(true)
    end
  end

  describe 'paid subscription expiration' do
    let!(:oldest_team) do
      create(
        :team,
        stripe_customer_rid: 'cust_someid',
        stripe_expires_at: (App.subscription_grace_period + 1.day).ago
      )
    end
    let!(:old_team) do
      create(:team, stripe_customer_rid: 'cust_someid', stripe_expires_at: 1.day.ago)
    end
    let!(:new_team) do
      create(:team, stripe_customer_rid: 'cust_someid', stripe_expires_at: 1.day.from_now)
    end

    before { service }

    it 'deactivates the team that is expired beyond grace period' do
      expect(oldest_team.reload.active?).to be(false)
    end

    it 'does not deactivate other teams' do
      expect(old_team.reload.active?).to be(true)
      expect(new_team.reload.active?).to be(true)
    end
  end
end
