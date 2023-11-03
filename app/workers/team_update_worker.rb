class TeamUpdateWorker
  include Sidekiq::Worker

  def perform(team_rid, name, avatar_url = nil)
    team = Team.find_by!(rid: team_rid)
    return if team.inactive?
    TeamUpdateService.call(team:, name:, avatar_url:)
  end
end
