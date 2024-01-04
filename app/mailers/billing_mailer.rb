class BillingMailer < ApplicationMailer
  def app_uninstalled(team)
    @team = team
    mail to: team.admin_emails, subject: 'App uninstalled'
  end

  def auto_payment_problem(team)
    @team = team
    mail to: team.admin_emails, subject: 'Payment problem'
  end

  def subscription_canceled(team)
    @team = team
    mail to: team.admin_emails, subject: 'Subscription canceled'
  end

  def subscription_expired(team)
    @team = team
    mail to: team.admin_emails, subject: 'Subscription expired'
  end

  def team_over_plan(team)
    @team = team
    mail to: team.admin_emails, subject: 'Your subscription plan'
  end

  def team_under_plan(team)
    @team = team
    mail to: team.admin_emails, subject: 'Your subscription plan'
  end

  def team_oversized(team)
    @team = team
    mail to: team.admin_emails, subject: 'Team too large'
  end

  def trial_expires_soon(team)
    @team = team
    mail to: team.admin_emails, subject: 'Trial expires soon'
  end

  def trial_expired(team)
    @team = team
    mail to: team.admin_emails, subject: 'Trial expired'
  end
end
