class Actions::AppUninstalled < Actions::Base
  def call
    return unless team.active? # If already uninstalled, do nothing
    team.uninstall!(UNINSTALL_REASONS[:admin], call_slack: false)
    BillingMailer.app_uninstalled(team).deliver_later
  end

  private

  def team
    @team ||= Team.find_by(rid: params[:team_rid])
  end
end
