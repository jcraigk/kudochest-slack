class EmailsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def unsubscribe
    email = Rails.application.message_verifier(:unsubscribe).verify(params[:token])
    user = User.find_by!(email:)
    unsubscribe_from_all(user)
    flash.now[:notice] = t('users.unsubscribed_html', email:)
  end

  private

  def unsubscribe_from_all(user)
    user.owned_team&.update!(weekly_report: false)
    user.profile.update!(weekly_report: false)
  end
end
