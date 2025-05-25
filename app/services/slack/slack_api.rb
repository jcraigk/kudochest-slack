class Slack::SlackApi
  def self.client(opts = {})
    token = opts[:api_key] || Cache::TeamConfig.call(opts[:team_rid])[:api_key]
    Slack::Web::Client.new(token:)
  end
end
