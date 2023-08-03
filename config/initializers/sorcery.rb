Rails.application.config.sorcery.submodules = %i[external remember_me]

Rails.application.config.sorcery.configure do |config|
  config.cookie_domain = ENV.fetch('WEB_DOMAIN', 'localhost')
  config.user_class = 'User'
  config.user_config do |user|
    user.stretches = 1 if Rails.env.test?
    user.remember_me_token_persist_globally = true
    user.authentications_class = Authentication
  end

  # Slack
  config.external_providers = %i[slack]
  config.slack.callback_url = "#{App.base_url}/oauth/callback/slack"
  config.slack.key = ENV.fetch('SLACK_CLIENT_ID', nil)
  config.slack.secret = ENV.fetch('SLACK_CLIENT_SECRET', nil)
  config.slack.user_info_mapping = { email: 'email' }
end
