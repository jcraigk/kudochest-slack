class Hooks::Stripe::BaseController < Hooks::BaseController
  attr_reader :event

  before_action :verify_stripe_request!

  private

  def verify_stripe_request!
    @event = Stripe::Webhook.construct_event \
      request.body.read, request.env['HTTP_STRIPE_SIGNATURE'], App.stripe_webhook_secret
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Sentry.capture_exception(e)
    head :forbidden
  end
end
