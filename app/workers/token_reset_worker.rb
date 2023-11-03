class TokenResetWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform(team_id)
    team = Team.find(team_id)
    return if team.inactive?
    TokenResetService.call(team:)
  end
end
