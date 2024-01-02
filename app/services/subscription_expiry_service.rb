class SubscriptionExpiryService < Base::Service
  WARNING_PERIOD = 7.days

  # TODO: Split this into multiple workers to scale
  def call
    warn_team_size_mismatch
    warn_trials_expiring_soon
    uninstall_expired_trials
    uninstall_expired_subscriptions
  end

  private

  def warn_team_size_mismatch
    App.subscription_plans.each do |plan|
      teams_outside_plan_size(plan).find_each do |team|
        notice = team.member_count > plan.range.end ? :team_over_plan : :team_under_plan
        BillingMailer.send(notice, team).deliver_later
        team.update(team_size_notified_at: Time.current)
      end
    end
  end

  def teams_outside_plan_size(plan)
    Team.active
        .non_gratis
        .where(stripe_price_rid: plan.price_rid)
        .where('team_size_notified_at IS NULL OR team_size_notified_at < ?', 4.weeks.ago)
        .where.not('member_count BETWEEN ? AND ?', plan.range.begin, plan.range.end)
  end

  def warn_trials_expiring_soon
    teams_whose_trials_will_soon_expire.find_each do |team|
      team.update(trial_expiry_notified_at: Time.current)
      BillingMailer.trial_expires_soon(team).deliver_later
    end
  end

  def uninstall_expired_trials
    Team.active.trial_expired.find_each do |team|
      team.uninstall!('Trial expired')
      BillingMailer.trial_expired(team).deliver_later
    end
  end

  def uninstall_expired_subscriptions
    recent_expired_subscribed_teams.find_each do |team|
      team.uninstall!('Subscription expired')
      BillingMailer.subscription_expired(team).deliver_later
    end
  end

  def teams_whose_trials_will_soon_expire
    Team.active
        .non_gratis
        .never_subscribed
        .where(trial_expiry_notified_at: nil)
        .where \
          'DATE(trial_expires_at) BETWEEN ? AND ?',
          1.day.from_now.to_date,
          WARNING_PERIOD.from_now.to_date
  end

  def recent_expired_subscribed_teams
    Team.active
        .non_gratis
        .subscribed_at_least_once
        .where('DATE(stripe_expires_at) < ?', App.subscription_grace_period.ago.to_date)
  end
end
