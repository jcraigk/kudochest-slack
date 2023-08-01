class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]
  before_action :use_public_layout

  def new
    return redirect_to dashboard_path if current_user
    @user = User.new
  end

  def create
    if login(params[:email], params[:password], true)
      redirect_back_or_to dashboard_path
    else
      flash.now[:alert] = t('auth.login_fail')
      render action: :new
    end
  end

  def destroy
    logout
    redirect_to login_path, notice: t('auth.logged_out')
  end
end
