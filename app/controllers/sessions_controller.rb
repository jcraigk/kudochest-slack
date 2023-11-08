class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new]
  before_action :use_public_layout

  def new
    redirect_to dashboard_path if current_profile
  end

  def destroy
    cookies.delete(:auth_token)
    redirect_to root_path, notice: t('auth.logged_out')
  end
end
