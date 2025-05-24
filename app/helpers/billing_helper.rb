module BillingHelper
  def stripe_cancel_button
    link_to \
      icon_and_text("lock", t("billing.cancel_title")),
      stripe_cancel_subscriptions_path,
      class: "button is-danger is-light mr-2",
      method: :patch,
      data: { confirm: t("billing.cancel_confirm") }
  end

  def stripe_subscribe_button(team)
    i18n_key = team.stripe_subscription_rid.present? ? "resubscribe_now" : "subscribe_now"
    link_to \
      icon_and_text("lock", t("billing.#{i18n_key}")),
      stripe_checkout_start_subscriptions_path,
      class: "button is-primary is-medium",
      method: :post
  end

  def subscription_explanation(team, plan)
    t \
      "billing.explanation_html",
      count: team.member_count,
      name: plan.name,
      price: plan.price,
      url: pricing_url
  end

  def subscription_plan_name(team)
    if team.gratis_subscription?
      t("billing.gratis_subscription")
    elsif team.trial?
      t("billing.trial_subscription")
    elsif team.active?
      team.subscription_plan.name
    else
      t("billing.subscription_expired")
    end
  end
end
