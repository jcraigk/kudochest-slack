class SlackController < ApplicationController
  skip_before_action :require_login

  def install
    redirect_uri = CGI.escape("#{App.base_url}/slack/install_callback")
    url = "https://slack.com/oauth/v2/authorize?client_id=#{App.slack_client_id}&scope=#{App.slack_oauth_scopes.join(',')}&redirect_uri=#{redirect_uri}&state=#{init_state}"
    redirect_to url, allow_other_host: true
  end

  def login
    redirect_uri = CGI.escape("#{App.base_url}/slack/login_callback")
    url = "https://slack.com/openid/connect/authorize?response_type=code&scope=openid,profile&client_id=#{App.slack_client_id}&redirect_uri=#{redirect_uri}&state=#{init_state}"
    redirect_to url, allow_other_host: true
  end

  def install_callback
    return login_failed unless state_match?
    notice = TeamRegistrar.call(**team_data) ? t("onboarding.welcome") : t("auth.already_installed")
    login_profile(installer_profile_rid)
    redirect_to dashboard_path, notice:
  rescue Slack::Web::Api::Errors::SlackError, ArgumentError
    redirect_after_error
  end

  def login_callback
    return login_failed unless state_match?
    return redirect_to dashboard_path if login_profile(login_profile_rid)
    login_failed(t("auth.not_installed"))
  end

  private

  def login_failed(message = nil)
    redirect_to root_path, alert: message || t("auth.login_fail")
  end

  def init_state
    state = SecureRandom.hex(4)
    session[:state] = state
    state
  end

  def state_match?
    session[:state] == params[:state]
  end

  def open_id_data
    Slack::Web::Client.new.openid_connect_token(
      client_id: App.slack_client_id,
      client_secret: App.slack_client_secret,
      code: params[:code],
      redirect_uri: "#{App.base_url}/slack/login_callback"
    ).deep_symbolize_keys
  end

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
      name: oauth_data[:team][:name],
      avatar_url:,
      installer_profile_rid:,
      api_key:
    }
  end

  def avatar_url
    Slack::SlackApi.client(api_key:).team_info(team: team_rid)[:team][:icon][:image_230]
  end

  def team_rid
    oauth_data[:team][:id]
  end

  def api_key
    oauth_data[:access_token]
  end

  def login_profile_rid
    data = JWT.decode(open_id_data[:id_token], nil, false).first
    data["https://slack.com/user_id"]
  end

  def installer_profile_rid
    oauth_data[:authed_user][:id]
  end

  def redirect_after_error
    redirect_to dashboard_path, alert: t("auth.install_error")
  end
end
