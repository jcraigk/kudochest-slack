require_relative "boot"

require "rails"
require "action_cable/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

module KudoChest
  class Application < Rails::Application
    config.load_defaults 8.0
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
    config.exceptions_app = routes
    config.hosts.clear # TODO: remove this
    config.action_cable.allowed_request_origins = [ %r{ http://* }, %r{https://*} ]
    config.action_cable.worker_pool_size = 4
    config.active_job.queue_adapter = :sidekiq

    # Basic
    config.app_name = "KudoChest"
    config.bot_name = "KudoChest"
    config.base_url = ENV.fetch("BASE_URL", "https://#{ENV.fetch('WEB_DOMAIN', 'localhost')}")
    config.from_email = ENV.fetch \
      "FROM_EMAIL",
      "#{config.app_name} <noreply@#{ENV.fetch('WEB_DOMAIN', 'localhost')}>"
    config.max_teams = ENV.fetch("MAX_TEAMS", 1)
    config.point_term = ENV.fetch("POINT_TERM", "kudo")
    config.points_term = ENV.fetch("POINTS_TERM", "kudos")
    config.jab_term = ENV.fetch("JAB_TERM", "kudont")
    config.jabs_term = ENV.fetch("JABS_TERM", "kudonts")
    config.point_singular_prefix = ENV.fetch("POINT_SINGULAR_PREFIX", "a")
    config.jab_singular_prefix = ENV.fetch("JAB_SINGULAR_PREFIX", "a")
    config.help_url = "https://github.com/jcraigk/kudochest-slack"
    config.asset_host = ENV.fetch("ASSET_HOST", nil)

    # Slack
    config.slack_app_id = ENV.fetch("SLACK_APP_ID", nil)
    config.slack_signing_secret = ENV.fetch("SLACK_SIGNING_SECRET", nil)
    config.slack_oauth_scopes = %w[
      channels:history
      channels:join
      channels:read
      chat:write
      commands
      emoji:read
      groups:history
      groups:read
      im:history
      im:read
      im:write
      mpim:history
      mpim:read
      reactions:read
      team:read
      usergroups:read
      users:read
      users:read.email
      users.profile:read
    ]
    config.base_command = ENV.fetch("BASE_COMMAND", "kudos")
    config.default_point_emoji = "star"
    config.default_jab_emoji = "arrow_down"
    config.default_ditto_emoji = "heavy_plus_sign"
    config.slack_client_id = ENV.fetch("SLACK_CLIENT_ID", nil)
    config.slack_client_secret = ENV.fetch("SLACK_CLIENT_SECRET", nil)
    config.slack_custom_emoji_url = "https://slack.com/help/articles/206870177-Add-custom-emoji"

    # Email
    config.action_mailer.default_url_options = { host: config.base_url }
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      authentication: :plain,
      address: ENV.fetch("SMTP_ADDRESS", nil),
      port: 587,
      user_name: ENV.fetch("SMTP_USERNAME", nil),
      password: ENV.fetch("SMTP_PASSWORD", nil)
    }

    # Features
    config.max_response_mentions = 3
    config.undo_cutoff = 1.minute
    config.max_points_per_tip = 10
    config.default_max_level = 20
    config.default_max_level_points = 1_000
    config.error_emoji = "grimacing"
    config.default_throttle_quantity = 100
    config.max_throttle_quantity = 10_000
    config.default_team_time_zone = "Pacific Time (US & Canada)"
    config.default_streak_duration = 5
    config.min_streak_duration = 3
    config.max_streak_duration = 100
    config.default_streak_reward = 1
    config.max_streak_reward = 5
    config.channel_cache_ttl = 5.minutes
    config.default_leaderboard_size = 5
    config.modal_cache_ttl = 600 # seconds
    config.gentle_level_coefficient = 1.5
    config.steep_level_coefficient = 2.1
    config.default_tip_history_days = 14
    config.max_note_length = 255
    config.give_color = "#460878"
    config.receive_color = "#247808"
  end
end

App = Rails.configuration

# Errors
class ChatFeedbackError < StandardError; end
class ThrottleExceededError < StandardError; end

# Structs
ChannelData = Struct.new(:rid, :name)
ChatResponse = Struct.new(:mode, :text, :image, :response, :tips, keyword_init: true)
EntityMention = Struct.new(:entity, :profiles, :topic_id, :quantity, :note, keyword_init: true)
Mention = Struct.new(:rid, :topic_id, :quantity, :note, keyword_init: true)
LeaderboardProfile = Struct.new \
  :id, :rank, :previous_rank, :slug, :link, :display_name, :real_name,
  :points, :last_timestamp, :avatar_url, keyword_init: true
LeaderboardPage = Struct.new(:updated_at, :profiles)

# App constants, will rarely change
STORAGE_PATH =
  if Rails.env.test?
    Rails.root.join("tmp/storage")
  elsif ENV.fetch("IN_DOCKER", false)
    "/storage"
  else
    ENV.fetch("STORAGE_PATH", "/")
  end

COMMAND_KEYWORDS = {
  admin: %w[],
  connect: %w[],
  claim: %w[buy get],
  help: %w[h support],
  leaderboard: %w[top leaders best],
  levels: %w[level leveling],
  preferences: %w[config setup options settings prefs],
  report: %w[digest activity weekly summary],
  shop: %w[items loot rewards],
  stats: %w[me],
  topics: %w[],
  undo: %w[revoke]
}.freeze

PRIVATE_KEYWORDS = %w[admin help claim].freeze
CHAN_PREFIX = "#".freeze
PROF_PREFIX = "@".freeze
LEGACY_SLACK_SUFFIX_PATTERN = '\|[^>]*'.freeze
RID_CHARS = "[A-Z0-9]"
PROFILE_PREFIX = "@"
SUBTEAM_PREFIX = "!subteam^"
PROFILE_REGEX = /<@([A-Z0-9]+)(\|([^>]+))?>/
CHANNEL_REGEX = /<#([A-Z0-9]+)(\|([^>]+))?>/
SUBTEAM_REGEX = /<!subteam\^([^>]+)>/

SLACK_DM_NAME = "direct-message".freeze
SLACK_DM_PREFIX = "mpdm-".freeze
SLACK_DM_PHRASE = "a group chat".freeze

POINT_INLINES = %w[++ += +].freeze
JAB_INLINES = %w[-- -= -].freeze
THUMBSUP_EMOJI_PATTERNS = [ '\+1(::skin-tone-\d)?', "thumbsup" ].freeze

IMG_DELIM = "<COLOR>".freeze
GIFS = {
  "32" => %w[trophy],
  "48" => %w[cake cherries comet confetti fern fire flower star tree]
}.freeze
