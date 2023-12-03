module TeamDecorator
  extend ActiveSupport::Concern

  def oversized?
    member_count > App.max_team_size
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: api_key)
  end

  def levels_table
    last_points = 0
    rows = level_points_map.map do |level, points|
      delta = points - last_points
      last_points = points
      levels_table_row(level, points, delta)
    end
    (levels_table_titles + rows).join("\n")
  end

  def delinquent?
    no_subscription? && trial_expires_at.past?
  end

  def trial?
    no_subscription? && trial_expires_at.future?
  end

  def no_subscription?
    !gratis_subscription? && !current_subscription?
  end

  def current_subscription?
    stripe_expires_at&.future? || false
  end

  def recurring_subscription?
    current_subscription? && !stripe_canceled_at? && !stripe_declined_at?
  end

  def subscribed_at_least_once?
    stripe_expires_at.present?
  end

  def active?
    uninstalled_at.nil?
  end

  def inactive?
    uninstalled_at.present?
  end

  def subscription_plan
    App.subscription_plans.find { |plan| plan.price_rid == stripe_price_rid }
  end

  def point_emoj
    ":#{point_emoji}:"
  end

  def jab_emoj
    ":#{jab_emoji}:"
  end

  def ditto_emoj
    ":#{ditto_emoji}:"
  end

  def throttle_period_days
    {
      'day' => 1,
      'week' => 7,
      'month' => 30
    }[throttle_period]
  end

  def exempt_profiles_sentence
    profile_links =
      profiles.active
              .where(throttle_exempt: true)
              .sort_by(&:display_name)
              .map(&:link)

    return 'None' if profile_links.empty?
    profile_links.to_sentence
  end

  def level_points_map
    (1..max_level).index_with { |level| LevelToPointsService.call(team: self, level:) }
  end

  def workspace_noun
    case platform
    when 'slack' then 'workspace'
    end
  end

  def plat
    platform.to_s.titleize
  end

  def config
    Cache::TeamConfig.call(platform, rid)
  end

  def total_points
    deduct_jabs? ? balance : points_sent
  end

  def emojis
    slack_client.emoji_list['emoji'].keys
  end

  def onboarded_channels?
    onboarded_channels_at.present?
  end

  def onboarded_emoji?
    onboarded_emoji_at.present?
  end

  def onboarded?
    onboarded_channels? && onboarded_emoji?
  end

  private

  def levels_table_titles
    [
      "Level  #{App.points_term.titleize}  Delta",
      "-----  #{'-' * App.points_term.size}  -----"
    ]
  end

  def levels_table_row(level, points, delta)
    format(
      "%<level>-5d  %<points>-#{App.points_term.size}d  %<delta>-5d",
      level:,
      points:,
      delta:
    ).strip
  end
end
