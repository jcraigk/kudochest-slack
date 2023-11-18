class SubscriptionExpiryWorker
  include Sidekiq::Worker

  def perform
    SubscriptionExpiryService.call
  end
end
