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
    config.app_name = ENV.fetch("APP_NAME", "KudoChest")
    config.base_url = ENV.fetch("BASE_URL", "localhost")
    config.from_email = ENV.fetch("FROM_EMAIL", "noreply@localhost")
    config.max_teams = ENV.fetch("MAX_TEAMS", 1)
    config.point_term = ENV.fetch("POINT_TERM", "kudo")
    config.points_term = ENV.fetch("POINTS_TERM", "kudos")
    config.jab_term = ENV.fetch("JAB_TERM", "kudont")
    config.jabs_term = ENV.fetch("JABS_TERM", "kudonts")
    config.point_singular_prefix = ENV.fetch("POINT_SINGULAR_PREFIX", "a")
    config.jab_singular_prefix = ENV.fetch("JAB_SINGULAR_PREFIX", "a")
    config.help_url = "https://github.com/jcraigk/kudochest-slack"
    config.asset_host = ENV["ASSET_HOST"] if ENV["ASSET_HOST"].present?

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
    config.max_response_mentions = ENV.fetch("MAX_RESPONSE_MENTIONS", 3).to_i
    config.undo_cutoff = ENV.fetch("UNDO_CUTOFF_SECONDS", 60).to_i.seconds
    config.max_points_per_tip = ENV.fetch("MAX_POINTS_PER_TIP", 10).to_i
    config.default_max_level = ENV.fetch("DEFAULT_MAX_LEVEL", 20).to_i
    config.default_max_level_points = ENV.fetch("DEFAULT_MAX_LEVEL_POINTS", 1_000).to_i
    config.error_emoji = ENV.fetch("ERROR_EMOJI", "grimacing")
    config.default_throttle_quantity = ENV.fetch("DEFAULT_THROTTLE_QUANTITY", 100).to_i
    config.max_throttle_quantity = ENV.fetch("MAX_THROTTLE_QUANTITY", 10_000).to_i
    config.default_team_time_zone = ENV.fetch("DEFAULT_TEAM_TIME_ZONE", "Pacific Time (US & Canada)")
    config.default_streak_duration = ENV.fetch("DEFAULT_STREAK_DURATION", 5).to_i
    config.min_streak_duration = ENV.fetch("MIN_STREAK_DURATION", 3).to_i
    config.max_streak_duration = ENV.fetch("MAX_STREAK_DURATION", 100).to_i
    config.default_streak_reward = ENV.fetch("DEFAULT_STREAK_REWARD", 1).to_i
    config.max_streak_reward = ENV.fetch("MAX_STREAK_REWARD", 5).to_i
    config.channel_cache_ttl = ENV.fetch("CHANNEL_CACHE_TTL_MINUTES", 5).to_i.minutes
    config.default_leaderboard_size = ENV.fetch("DEFAULT_LEADERBOARD_SIZE", 5).to_i
    config.modal_cache_ttl = ENV.fetch("MODAL_CACHE_TTL_SECONDS", 600).to_i
    config.gentle_level_coefficient = ENV.fetch("GENTLE_LEVEL_COEFFICIENT", 1.5).to_f
    config.steep_level_coefficient = ENV.fetch("STEEP_LEVEL_COEFFICIENT", 2.1).to_f
    config.tip_history_days = ENV.fetch("TIP_HISTORY_DAYS", 14).to_i
    config.max_note_length = ENV.fetch("MAX_NOTE_LENGTH", 255).to_i
    config.give_color = ENV.fetch("GIVE_COLOR", "#460878")
    config.receive_color = ENV.fetch("RECEIVE_COLOR", "#247808")
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
