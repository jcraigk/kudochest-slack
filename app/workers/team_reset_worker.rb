class TeamResetWorker
  include Sidekiq::Worker

  def perform(team_id)
    team = Team.find(team_id)
    TeamResetService.call(team:)
  end
end
