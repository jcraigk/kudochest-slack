class Oauth::SlackController < ApplicationController
  def add_to_slack
    url = "https://slack.com/oauth/v2/authorize?client_id=#{App.slack_client_id}&scope=#{App.slack_oauth_scopes.join(',')}"
    redirect_to url, allow_other_host: true
  end

  def integration
    TeamRegistrar.call(**team_data)
    redirect_to dashboard_path
  rescue Slack::Web::Api::Errors::SlackError, ArgumentError
    redirect_to dashboard_path, alert: t('oauth.basic_error')
  end

  private

  def oauth_data
    @oauth_data ||=
      Slack::Web::Client.new.oauth_v2_access(
        client_id: App.slack_client_id,
        client_secret: App.slack_client_secret,
        code: params[:code]
      ).deep_symbolize_keys
  end

  def team_data
    {
      platform: :slack,
      rid: team_rid,
      name: team_params[:name],
      avatar_url:,
      owner_user_id: current_user.id,
      api_key:
    }
  end

  def avatar_url
    Slack::SlackApi.client(api_key:).team_info(team: team_rid)[:team][:icon][:image_230]
  end

  def team_params
    @team_params ||= oauth_data[:team]
  end

  def team_rid
    @team_rid ||= team_params[:id]
  end

  def api_key
    @api_key ||= oauth_data[:access_token]
  end
end
