class SubscriptionsController < ApplicationController
  before_action :find_suggested_plan, only: %i[index stripe_checkout_start]

  def index
    authorize current_team
    flash[:notice] = t("billing.checkout_success") if params[:success] == "true"
  end

  def stripe_checkout_start
    authorize current_team
    create_or_use_stripe_customer
    start_stripe_session
  end

  def stripe_checkout_success
    redirect_to subscriptions_path, notice: t("billing.checkout_success") if payment_success?
  end

  def stripe_checkout_cancel
    redirect_to subscriptions_path, notice: t("billing.checkout_aborted")
  end

  def stripe_cancel
    authorize current_team
    cancel_subscription_and_email_admins
    redirect_to subscriptions_path, notice: t("billing.subscription_canceled")
  end

  def payment_confirmation
    render plain: payment_success?.to_s
  end

  private

  def payment_success?
    current_team.current_subscription?
  end

  def cancel_subscription_and_email_admins
    cancel_current_subscription
    current_team.update!(stripe_canceled_at: Time.current)
    BillingMailer.subscription_canceled(team).deliver_later
  end

  def cancel_current_subscription
    Stripe::Subscription.cancel(current_team.stripe_subscription_rid)
  rescue Stripe::InvalidRequestError => e
    msg = e.message.include?("No such subscription") ? "Invalid subscription" : e.message
    flash[:alert] = msg
  end

  def create_or_use_stripe_customer
    return if current_team.stripe_customer_rid.present?
    current_team.update(stripe_customer_rid: new_customer.id)
  end

  def new_customer
    Stripe::Customer.create \
      email: current_profile.email,
      name: current_team.name
  end

  def start_stripe_session
    @stripe_session_id = Stripe::Checkout::Session.create(
      customer: current_team.stripe_customer_rid,
      payment_method_types: %w[card],
      line_items: [ { price: @suggested_plan.price_rid, quantity: 1 } ],
      success_url: stripe_checkout_success_subscriptions_url,
      cancel_url: stripe_checkout_cancel_subscriptions_url,
      mode: "subscription"
    ).id
  end

  def find_suggested_plan
    @suggested_plan = App.subscription_plans.find do |plan|
      plan.range.include?(current_team.member_count)
    end
  end
end
