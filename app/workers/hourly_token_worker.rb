class HourlyTokenWorker
  include Sidekiq::Worker

  attr_reader :processed_teams

  def perform
    disburse_tokens
  end

  private

  def disburse_tokens
    Team.throttled
        .active
        .where('next_tokens_at <= ?', Time.current.beginning_of_hour)
        .find_each do |team|
      TokenDisbursalWorker.perform_async(team.id)
    end
  end
end
