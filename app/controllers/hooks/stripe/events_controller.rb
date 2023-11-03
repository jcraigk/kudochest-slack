class Hooks::Stripe::EventsController < Hooks::Stripe::BaseController
  def receiver # rubocop:disable Metrics/MethodLength
    # Rails.logger.info('-------- STRIPE EVENT --------')
    # Rails.logger.info(event)

    case event.type
    when 'invoice.payment_succeeded'
      handle_auto_payment_succeeded
    when 'invoice.payment_failed',
         'invoice.payment_action_required'
      handle_auto_payment_failed
    when 'checkout.session.completed'
      handle_checkout_succeeded
    when 'checkout.session.failed',
         'checkout.session.async_payment_failed',
         'checkout.session.expired'
      handle_checkout_failed
    end

    head :ok
  end

  private

  def handle_auto_payment_succeeded
    team.update!(basic_stripe_attrs)
  end

  def handle_auto_payment_failed
    BillingMailer.auto_payment_problem(team).deliver_later
    team.update!(stripe_declined_at: Time.current)
  end

  def handle_checkout_succeeded
    team.update!(checkout_attrs.merge(basic_stripe_attrs))
  end

  def checkout_attrs
    {
      stripe_subscription_rid: data[:subscription],
      stripe_price_rid:
    }
  end

  def basic_stripe_attrs
    {
      stripe_expires_at:, # Key field! Must stay updated to maintain service!
      stripe_canceled_at: nil,
      stripe_declined_at: nil
    }
  end

  def stripe_price_rid
    subscription.items.data.first.price.id
  end

  def stripe_expires_at
    Time.zone.at(subscription.current_period_end)
  end

  def subscription
    @subscription ||= Stripe::Subscription.retrieve(data[:subscription])
  end

  def handle_checkout_failed
    team.update!(stripe_declined_at: Time.current)
  end

  def team
    @team ||= Team.find_by!(stripe_customer_rid: data[:customer])
  end

  def data
    @data ||= event.data.object
  end
end
