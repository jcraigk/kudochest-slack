class ChannelSyncWorker
  include Sidekiq::Worker

  def perform(team_rid, new_channel_rid = nil)
    team = Team.find_by!(rid: team_rid)
    return if team.inactive?
    Slack::ConstService.call("ChannelSyncService").call(team:, new_channel_rid:)
  end
end
