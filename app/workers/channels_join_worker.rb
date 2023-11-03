class ChannelsJoinWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  attr_reader :team_id, :channel_rids

  def perform(team_id, channel_rids = [])
    @team_id = team_id
    @channel_rids = channel_rids.any? ? channel_rids : team.channels.pluck(:rid)

    return if team.inactive?

    join_channels
  end

  private

  def join_channels
    channel_rids.each do |rid|
      Slack::ChannelJoinService.call(team:, channel_rid: rid)
      sleep 0.3 unless Rails.env.test?
    end
  end

  def team
    @team ||= Team.find(team_id)
  end
end
