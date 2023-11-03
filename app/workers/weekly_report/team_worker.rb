class WeeklyReport::TeamWorker
  include ActionView::Helpers::TextHelper
  include Sidekiq::Worker

  COOLDOWN = 6.days.freeze

  attr_reader :team_id

  def perform(team_id)
    @team_id = team_id

    return unless send_weekly_report?

    send_email
  end

  private

  def send_weekly_report?
    team.weekly_report? &&
      (
        team.weekly_report_notified_at.nil? ||
        team.weekly_report_notified_at < COOLDOWN.ago
      )
  end

  def send_email
    WeeklyReportMailer.team_report(team_data).deliver
    team.update!(weekly_report_notified_at: Time.current)
  end

  def team_data
    Reports::TeamDigestService.call(team:)
  end

  def team
    @team ||= Team.find(team_id)
  end
end
