class SubteamSyncWorker
  include Sidekiq::Worker

  def perform(team_rid)
    team = Team.find_by!(rid: team_rid)
    return if team.inactive?
    Slack::ConstService.call("SubteamSyncService").call(team:)
  end
end
