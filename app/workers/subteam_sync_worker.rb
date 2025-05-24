class SubteamSyncWorker
  include Sidekiq::Worker

  def perform(team_rid)
    team = Team.find_by!(rid: team_rid)
    return if team.inactive?
    ConstService.call(team.plat, "SubteamSyncService").call(team:)
  end
end
