class DashboardController < ApplicationController
  def show
    return redirect_to(oauth_add_to_slack_path) if current_user.owned_teams.none?
    return unless current_profile

    # TODO: This is a hack to fix kaminari anchor bug
    if params[:paged].present?
      return redirect_to dashboard_path(page: params[:page], anchor: :recent)
    end

    build_dashboard_for(current_profile)
  end
end
