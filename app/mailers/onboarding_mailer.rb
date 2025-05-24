class OnboardingMailer < ApplicationMailer
  def welcome(team)
    @team = team
    mail to: team.admin_emails, subject: "Welcome"
  end
end
