class Team < ApplicationRecord
  include Sluggi::Slugged
  include TeamDecorator

  WEEKDAYS = Date::DAYNAMES.map(&:downcase).freeze
  CONFIG_ATTRS = %w[
    api_key app_profile_rid avatar_url enable_cheers
    point_emoji jab_emoji ditto_emoji enable_emoji enable_jabs
    log_channel_rid hint_channel_rid max_points_per_tip
    platform response_mode response_theme show_channel show_note time_zone
    tip_notes enable_topics require_topic topics rid
  ].freeze
  CONFIG_CACHE_TTL = 5.minutes

  has_many :channels, dependent: :destroy
  has_many :profiles, dependent: :destroy
  has_many :subteams, dependent: :destroy
  has_many :topics, dependent: :destroy
  has_many :rewards, dependent: :destroy

  enumerize :platform,
            in: %w[slack]
  enumerize :level_curve,
            in: %w[gentle steep linear],
            default: 'gentle'
  enumerize :response_mode,
            in: %w[adaptive convo reply direct silent],
            default: 'adaptive'
  # TODO: Re-enable graphical responses
  # Disabled themes: %w[gif_day gif_night]
  enumerize :response_theme,
            in: %w[basic fancy quiet quiet_stat],
            default: 'quiet_stat'
  enumerize :tip_notes,
            in: %w[optional required disabled],
            default: 'optional'
  enumerize :throttle_period,
            in: %w[day week month],
            default: 'week'
  enumerize :hint_frequency,
            in: %w[never hourly daily weekly],
            default: 'never'

  attribute :enable_cheers,      :boolean, default: true
  attribute :enable_emoji,       :boolean, default: true
  attribute :enable_levels,      :boolean, default: true
  attribute :enable_loot,        :boolean, default: false
  attribute :enable_streaks,     :boolean, default: true
  attribute :enable_topics,      :boolean, default: false
  attribute :enable_jabs,        :boolean, default: false
  attribute :deduct_jabs,        :boolean, default: false
  attribute :installed,          :boolean, default: true
  attribute :require_topic,      :boolean, default: false
  attribute :show_channel,       :boolean, default: true
  attribute :show_note,          :boolean, default: true
  attribute :split_tip,          :boolean, default: false
  attribute :weekly_report,      :boolean, default: false
  attribute :point_emoji,        :string,  default: -> { App.default_point_emoji }
  attribute :ditto_emoji,        :string,  default: -> { App.default_ditto_emoji }
  attribute :jab_emoji,          :string,  default: -> { App.default_jab_emoji }
  attribute :time_zone,          :string,  default: -> { App.default_team_time_zone }
  attribute :streak_duration,    :integer, default: -> { App.default_streak_duration }
  attribute :streak_reward,      :integer, default: -> { App.default_streak_reward }
  attribute :max_level,          :integer, default: -> { App.default_max_level }
  attribute :max_level_points,   :integer, default: -> { App.default_max_level_points }
  attribute :throttle_quantity,  :integer, default: -> { App.default_throttle_quantity }
  attribute :work_days_mask,     :integer, default: 62 # monday - friday
  attribute :member_count,       :integer, default: 0
  attribute :max_points_per_tip, :integer, default: 5

  validates :platform, presence: true
  validates :api_key, uniqueness: true
  validates :name, presence: true
  validates :rid, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :avatar_url, presence: true
  validates :throttle_quantity, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_throttle_quantity
  }
  validates :max_level, numericality: {
    greater_than_or_equal_to: 10,
    less_than_or_equal_to: 99
  }
  validates :max_level_points, numericality: {
    greater_than_or_equal_to: 100,
    less_than_or_equal_to: 10_000
  }
  validates :max_points_per_tip, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_points_per_tip
  }
  validates :streak_duration, numericality: {
    greater_than_or_equal_to: App.min_streak_duration,
    less_than_or_equal_to: App.max_streak_duration
  }
  validates :streak_reward, numericality: {
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: App.max_streak_reward
  }
  validates_with RequireTopicValidator
  validates_with WorkDaysValidator

  before_update :sync_topic_attrs
  after_update_commit :join_log_channel, if: :saved_change_to_log_channel_rid?

  scope :active, -> { where(uninstalled_at: nil) }
  scope :trial_expired, lambda {
    non_gratis.never_subscribed.where('trial_expires_at < ?', Time.current)
  }
  scope :subscribed_at_least_once, -> { where.not(stripe_expires_at: nil) }
  scope :never_subscribed, -> { where(stripe_expires_at: nil) }
  scope :gratis, -> { where(gratis_subscription: true) }
  scope :non_gratis, -> { where(gratis_subscription: false) }

  def work_days=(weekdays)
    self.work_days_mask = (weekdays & WEEKDAYS).sum { |d| 2**WEEKDAYS.index(d) }
  end

  def work_days
    WEEKDAYS.reject do |d|
      ((work_days_mask.to_i || 0) & (2**WEEKDAYS.index(d))).zero?
    end
  end

  def app_profile
    @app_profile ||= profiles.find_by(rid: app_profile_rid)
  end

  def uninstall!(reason, call_slack: true)
    if call_slack
      slack_client.apps_uninstall \
        client_id: App.slack_client_id,
        client_secret: App.slack_client_secret
    end
    update!(uninstalled_at: Time.current, uninstalled_by: reason)
  end

  private

  def slug_candidates
    [name, "#{name}-#{SecureRandom.hex(3)}"]
  end

  def slug_value_changed?
    name_changed?
  end

  def join_log_channel
    return if log_channel_rid.blank?
    Slack::ChannelJoinService.call(team: self, channel_rid: log_channel_rid)
  end

  def sync_topic_attrs
    self.require_topic = false unless enable_topics?
  end
end
