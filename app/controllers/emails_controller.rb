class EmailsController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_login

  def unsubscribe
    email = Rails.application.message_verifier(:unsubscribe).verify(params[:token])
    profile = Profile.find_by!(email:)
    unsubscribe_from_all(profile)
    path = current_profile ? dashboard_path : root_path
    redirect_to path, notice: t('profiles.unsubscribed_html', email:)
  end

  private

  def unsubscribe_from_all(profile)
    profile.owned_team&.update!(weekly_report: false)
    profile.update!(weekly_report: false)
  end
end
