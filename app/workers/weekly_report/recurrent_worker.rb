class WeeklyReport::RecurrentWorker
  include Sidekiq::Worker

  COOLDOWN = 6.days.freeze

  def perform
    run_team_report_workers
    run_profile_report_workers
  end

  private

  def run_team_report_workers
    Team.active
        .where(weekly_report: true)
        .where('created_at < ?', 1.week.ago)
        .where('weekly_report_notified_at IS NULL OR weekly_report_notified_at < ?', COOLDOWN.ago)
        .find_each do |team|
      WeeklyReport::TeamWorker.perform_async(team.id)
    end
  end

  def run_profile_report_workers
    profiles.find_each do |profile|
      next if profile.user&.email.blank?
      WeeklyReport::ProfileWorker.perform_async(profile.id)
    end
  end

  def profiles
    Profile
      .active
      .joins(:team)
      .where('team.created_at < ?', 1.week.ago)
      .where(team: { uninstalled_at: nil })
      .where(weekly_report: true)
      .where \
        'profiles.weekly_report_notified_at IS NULL OR profiles.weekly_report_notified_at < ?',
        6.days.ago
  end
end
