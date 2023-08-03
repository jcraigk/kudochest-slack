class Oauth::SorceryController < ApplicationController
  skip_before_action :require_login, raise: false

  def oauth
    redirect_to sorcery_login_url(params[:provider]), allow_other_host: true
  end

  def callback
    if login_from(params[:provider])
      auto_associate_profile
      redirect_back_or_to(dashboard_path)
    else
      create_user_and_login
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    redirect_to login_path, alert: t('auth.external_fail', provider: provider_title)
  end

  private

  def auto_associate_profile
    rid = current_user.authentications.find_by(provider: params[:provider])&.uid
    profile = Profile.find_by(rid:)
    return if profile.blank? || profile.user.present?
    profile.update!(user: current_user)
  end

  def create_user_and_login
    user = create_from(params[:provider])
    user.activate!
    reset_session
    auto_login(user)
    auto_associate_profile

    redirect_back_or_to(dashboard_path, notice: success_notice)
  rescue ActiveRecord::RecordNotUnique
    redirect_to login_path, alert: t('auth.email_taken', provider: provider_title)
  end

  def success_notice
    t('auth.external_success', provider: provider_title)
  end

  def auth_params
    params.permit(:code)
  end

  def provider_title
    params[:provider].titleize
  end
end

# TODO: https://github.com/Sorcery/sorcery/pull/288
class Sorcery::Providers::Slack
  def get_user_hash(access_token)
    auth_hash(access_token).tap do |h|
      h[:user_info] = fetch_user_info(access_token)['user']
      h[:uid] = h[:user_info]['id']
    end
  end

  private

  def fetch_user_info(access_token)
    return access_token if user_info_present?(access_token)
    JSON.parse(access_token.get(user_info_path).body)
  end

  def user_info_present?(access_token)
    access_token['user'].present? &&
      access_token['user']['id'].present? &&
      access_token['user']['email'].present?
  end
end
