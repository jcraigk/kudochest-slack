class OnboardingController < ApplicationController
  before_action :fetch_current_team

  def join_all_channels
    authorize current_team
    current_team.update!(join_channels: true)
    ChannelsJoinWorker.perform_async(current_team.id)
    channel_onboarding_complete unless params[:app_settings] == 'true'
    path = params[:app_settings] == 'true' ? app_settings_path : dashboard_path
    redirect_to path, notice: t('onboarding.join_all_channels_requested')
  end

  def join_specific_channels
    authorize current_team
    ChannelsJoinWorker.perform_async(current_team.id, selected_channel_rids)
    channel_onboarding_complete if params[:onboarding]
    redirect_to dashboard_path, notice: t('onboarding.join_channels_requested')
  end

  def skip_join_channels
    authorize current_team
    channel_onboarding_complete
    redirect_to \
      dashboard_path,
      notice: t('onboarding.join_channels_skipped', url: app_settings_path)
  end

  def confirm_emoji_added
    authorize current_team
    if emoji_added?
      current_team.update!(point_emoji: 'kudos', ditto_emoji: 'ditto_kudos')
      emoji_onboarding_complete
      emoji_added_success
    else
      emoji_added_fail
    end
  end

  def skip_emoji
    authorize current_team
    emoji_onboarding_complete
    redirect_to dashboard_path, notice: t('onboarding.emoji_skipped', url: app_settings_path)
  end

  private

  def emoji_added_success
    redirect_to \
      dashboard_path,
      notice: t('onboarding.emoji_added_success', url: app_settings_path)
  end

  def emoji_added_fail
    redirect_to \
      dashboard_path,
      alert: t('onboarding.emoji_added_fail', url: App.slack_custom_emoji_url)
  end

  def selected_channel_rids
    channel_rids = []
    params.select { |k, v| k.start_with?('channel_') && v == '1' }
          .each { |k, _v| channel_rids << k.split('_').last }
    channel_rids
  end

  def emoji_added?
    current_team.emojis.include?('kudos') && current_team.emojis.include?('ditto_kudos')
  end

  def channel_onboarding_complete
    current_team.update!(onboarded_channels_at: Time.now.utc)
  end

  def emoji_onboarding_complete
    current_team.update!(onboarded_emoji_at: Time.now.utc)
  end
end
