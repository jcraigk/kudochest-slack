class TeamSyncWorker
  include Sidekiq::Worker

  def perform(team_rid, first_run = false)
    team = Team.find_by!(rid: team_rid)
    return if team.inactive?
    Slack::ConstService.call("TeamSyncService").call(team:, first_run:)
  end
end
