class WeeklyReport::ProfileWorker
  include ActionView::Helpers::TextHelper
  include PointsHelper
  include Sidekiq::Worker

  COOLDOWN = 6.days.freeze
  CACHE_TTL = 10.minutes

  attr_reader :profile_id

  def perform(profile_id)
    @profile_id = profile_id

    return unless App.enable_email
    return unless send_weekly_report?

    send_email
  end

  private

  def send_weekly_report?
    profile.email.present? &&
      profile.weekly_report? &&
      (
        profile.weekly_report_notified_at.nil? ||
        profile.weekly_report_notified_at < COOLDOWN.ago
      )
  end

  def send_email
    WeeklyReportMailer.profile_report(profile_data, team_data).deliver
    profile.update!(weekly_report_notified_at: Time.current)
  end

  def profile_data
    Reports::ProfileDigestService.call(profile:)
  end

  def team_data
    Rails.cache.fetch(
      "weekly_report/#{profile.team.id}",
      expires_in: CACHE_TTL
    ) do
      Reports::TeamDigestService.call(team: profile.team)
    end
  end

  def profile
    @profile ||= Profile.includes(:team).find(profile_id)
  end
end
