class EventWorker
  include Sidekiq::Worker
  sidekiq_options queue: "critical"

  def perform(params)
    EventService.call(params: JSON.parse(params, symbolize_names: true))
  end
end
