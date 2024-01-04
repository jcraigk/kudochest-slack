class OnboardingMailer < ApplicationMailer
  def welcome(team)
    @team = team
    mail to: team.admin_emails, subject: 'Welcome'
  end

  # TODO: Vary the content based on app usage
  # def welcome_followup1(team)
  #   @team = team
  #   mail to: team.admin_emails, subject: 'How are things going?'
  # end

  # TODO: Vary the content based on app usage
  # def welcome_followup2(team)
  #   @team = team
  #   mail to: team.admin_emails, subject: 'Enjoying the app?'
  # end
end
