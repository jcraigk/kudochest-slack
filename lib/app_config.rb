class AppConfig
  class ConfigurationError < StandardError; end

  class << self
    def load_into_rails_config(config)
      load_basic_config(config)
      load_slack_config(config)
      load_email_config(config)
      load_features_config(config)
      load_constants_config(config)
    end

    private

    def load_basic_config(config)
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
      config.help_url = ENV.fetch("HELP_URL", "https://github.com/jcraigk/kudochest-slack")
      config.asset_host = ENV["ASSET_HOST"] if ENV["ASSET_HOST"].present?
    end

    def load_slack_config(config)
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
    end

    def load_email_config(config)
      config.action_mailer.default_url_options = { host: config.base_url }
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        authentication: :plain,
        address: ENV.fetch("SMTP_ADDRESS", nil),
        port: 587,
        user_name: ENV.fetch("SMTP_USERNAME", nil),
        password: ENV.fetch("SMTP_PASSWORD", nil)
      }
    end

    def load_features_config(config)
      config.max_response_mentions = parse_positive_int("MAX_RESPONSE_MENTIONS", 3)
      config.undo_cutoff = parse_positive_int("UNDO_CUTOFF_SECONDS", 60).seconds
      config.max_points_per_tip = parse_positive_int("MAX_POINTS_PER_TIP", 10)
      config.default_max_level = parse_positive_int("DEFAULT_MAX_LEVEL", 20)
      config.default_max_level_points = parse_positive_int("DEFAULT_MAX_LEVEL_POINTS", 1_000)
      config.error_emoji = ENV.fetch("ERROR_EMOJI", "grimacing")
      config.default_throttle_quantity = parse_positive_int("DEFAULT_THROTTLE_QUANTITY", 100)
      config.max_throttle_quantity = parse_positive_int("MAX_THROTTLE_QUANTITY", 10_000)
      config.default_team_time_zone = parse_time_zone("DEFAULT_TEAM_TIME_ZONE", "Pacific Time (US & Canada)")
      config.default_streak_duration = parse_positive_int("DEFAULT_STREAK_DURATION", 5)
      config.min_streak_duration = parse_positive_int("MIN_STREAK_DURATION", 3)
      config.max_streak_duration = parse_positive_int("MAX_STREAK_DURATION", 100)
      config.default_streak_reward = parse_positive_int("DEFAULT_STREAK_REWARD", 1)
      config.max_streak_reward = parse_positive_int("MAX_STREAK_REWARD", 5)
      config.channel_cache_ttl = parse_positive_int("CHANNEL_CACHE_TTL_MINUTES", 5).minutes
      config.default_leaderboard_size = parse_positive_int("DEFAULT_LEADERBOARD_SIZE", 5)
      config.modal_cache_ttl = parse_positive_int("MODAL_CACHE_TTL_SECONDS", 600)
      config.gentle_level_coefficient = parse_positive_float("GENTLE_LEVEL_COEFFICIENT", 1.5)
      config.steep_level_coefficient = parse_positive_float("STEEP_LEVEL_COEFFICIENT", 2.1)
      config.tip_history_days = parse_positive_int("TIP_HISTORY_DAYS", 14)
      config.max_note_length = parse_positive_int("MAX_NOTE_LENGTH", 255)
      config.give_color = parse_hex_color("GIVE_COLOR", "#460878")
      config.receive_color = parse_hex_color("RECEIVE_COLOR", "#247808")
    end

    def load_constants_config(config)
      # Command keywords
      config.command_keywords = {
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
      config.private_keywords = %w[admin help claim].freeze

      # Slack constants
      config.chan_prefix = "#".freeze
      config.prof_prefix = "@".freeze
      config.legacy_slack_suffix_pattern = '\|[^>]*'.freeze
      config.rid_chars = "[A-Z0-9]"
      config.profile_prefix = "@"
      config.subteam_prefix = "!subteam^"
      config.profile_regex = /<@([A-Z0-9]+)(\|([^>]+))?>/
      config.channel_regex = /<#([A-Z0-9]+)(\|([^>]+))?>/
      config.subteam_regex = /<!subteam\^([^>]+)>/

      config.slack_dm_name = "direct-message".freeze
      config.slack_dm_prefix = "mpdm-".freeze
      config.slack_dm_phrase = "a group chat".freeze

      # Point/Jab patterns
      config.point_inlines = %w[++ += +].freeze
      config.jab_inlines = %w[-- -= -].freeze
      config.thumbsup_emoji_patterns = [ '\+1(::skin-tone-\d)?', "thumbsup" ].freeze

      # Image/GIF constants
      config.img_delim = "<COLOR>".freeze
      config.gifs = {
        "32" => %w[trophy],
        "48" => %w[cake cherries comet confetti fern fire flower star tree]
      }.freeze

      # Storage path
      config.storage_path = begin
        if Rails.env.test?
          Rails.root.join("tmp/storage")
        elsif ENV.fetch("IN_DOCKER", false)
          "/storage"
        else
          ENV.fetch("STORAGE_PATH", "/")
        end
      end
    end

    def parse_positive_int(env_key, default)
      value = ENV[env_key]
      return default if value.blank?

      int_value = value.to_i
      if int_value <= 0
        raise ConfigurationError, "#{env_key} must be a positive integer (got: '#{value}')"
      end
      int_value
    end

    def parse_positive_float(env_key, default)
      value = ENV[env_key]
      return default if value.blank?

      float_value = value.to_f
      if float_value <= 0
        raise ConfigurationError, "#{env_key} must be a positive number (got: '#{value}')"
      end
      float_value
    end

    def parse_hex_color(env_key, default)
      value = ENV.fetch(env_key, default)
      unless value.match?(/\A#[0-9A-Fa-f]{6}\z/)
        raise ConfigurationError, "#{env_key} must be a valid hex color (e.g., #RRGGBB, got: '#{value}')"
      end
      value
    end

    def parse_time_zone(env_key, default)
      value = ENV.fetch(env_key, default)
      if defined?(ActiveSupport::TimeZone) && ActiveSupport::TimeZone[value].nil?
        raise ConfigurationError, "#{env_key} is not a valid time zone (got: '#{value}')"
      end
      value
    end
  end
end
