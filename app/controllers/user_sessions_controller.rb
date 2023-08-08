class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new]
  before_action :use_public_layout

  def new
    return redirect_to dashboard_path if current_user
  end

  def destroy
    logout
    redirect_to login_path, notice: t('auth.logged_out')
  end
end
