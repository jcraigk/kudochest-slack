require_relative "boot"

require "rails"
require "action_cable/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

# Load configuration management
require_relative "../lib/app_config"

Dotenv::Rails.logger = nil

module KudoChest
  class Application < Rails::Application
    config.load_defaults 8.0
    config.i18n.load_path += Dir[Rails.root.join("config/locales/**/*.yml")]
    config.exceptions_app = routes
    config.hosts.clear # TODO: remove this
    config.action_cable.allowed_request_origins = [ %r{ http://* }, %r{https://*} ]
    config.action_cable.worker_pool_size = 4
    config.active_job.queue_adapter = :sidekiq

    # Load all configuration from environment variables
    AppConfig.load_into_rails_config(config)
  end
end

# Global configuration accessor
App = Rails.configuration

# Application-specific errors
class ChatFeedbackError < StandardError; end
class ThrottleExceededError < StandardError; end

# Application structs
ChannelData = Struct.new(:rid, :name)
ChatResponse = Struct.new(:mode, :text, :image, :response, :tips, keyword_init: true)
EntityMention = Struct.new(:entity, :profiles, :topic_id, :quantity, :note, keyword_init: true)
Mention = Struct.new(:rid, :topic_id, :quantity, :note, keyword_init: true)
LeaderboardProfile = Struct.new \
  :id, :rank, :previous_rank, :slug, :link, :display_name, :real_name,
  :points, :last_timestamp, :avatar_url, keyword_init: true
LeaderboardPage = Struct.new(:updated_at, :profiles)
