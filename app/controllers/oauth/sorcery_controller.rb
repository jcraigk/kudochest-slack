class Oauth::SorceryController < ApplicationController
  skip_before_action :require_login, raise: false

  def oauth
    redirect_to sorcery_login_url(params[:provider]), allow_other_host: true
  end

  def callback
    if login_from(params[:provider])
      auto_associate_profile
      redirect_back_or_to dashboard_path
    else
      create_user_and_login
    end
  rescue StandardError => e
    Sentry.capture_exception(e)
    redirect_to root_path, alert: t('auth.external_fail', provider: provider_title)
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
    reset_session
    auto_login(user)
    auto_associate_profile
    redirect_back_or_to dashboard_path
  rescue ActiveRecord::RecordNotUnique => e
    Sentry.capture_exception(e)
    redirect_to root_path, alert: t('auth.login_fail', extra: { params: })
  end

  def auth_params
    params.permit(:code)
  end

  def provider_title
    params[:provider].titleize
  end
end
