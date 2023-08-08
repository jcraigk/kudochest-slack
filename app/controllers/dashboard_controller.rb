class DashboardController < ApplicationController
  def show
    if current_profile.present?
      standard_dashboard
    elsif !session[:installing]
      redirect_to oauth_add_to_slack_path
    elsif params[:paged].present?
      # TODO: This is a hack to fix kaminari anchor bug
      redirect_to dashboard_path(page: params[:page], anchor: :recent)
    end
  end

  private

  def standard_dashboard
    session[:installing] = false
    build_dashboard_for(current_profile)
  end
end
