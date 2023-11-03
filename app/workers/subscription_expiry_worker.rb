class SubscriptionExpiryWorker
  include Sidekiq::Worker
  sidekiq_options queue: :subscription_expiry

  def perform
    SubscriptionExpiryService.call
  end
end
