class Actions::AppUninstalled < Actions::Base
  def call
    team.uninstall!('Uninstalled via Slack by workspace admin', call_slack: false)
    BillingMailer.app_uninstalled(team).deliver_later
  end

  private

  def team
    @team ||= Team.find_by(rid: params[:team_rid])
  end
end
