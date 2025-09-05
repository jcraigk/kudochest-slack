class Slack::ChannelSyncService < Base::ChannelSyncService
  def call
    super
    join_new_channel
  end

  private

  def join_new_channel
    return unless new_channel_rid.present? && team.join_channels?
    Slack::ChannelJoinService.call(team:, channel_rid: new_channel_rid)
  end

  def fetch_remote_channels
    Enumerator.new do |yielder|
      cursor = nil
      loop do
        data = page_of_remote_channels(cursor)
        filter_local_channels(data[:channels]).each { |channel| yielder << channel }
        break if (cursor = data.dig(:response_metadata, :next_cursor)).blank?
      end
    end
  end

  def filter_local_channels(channels)
    channels.reject do |channel|
      channel[:is_shared] || channel[:is_org_shared] || channel[:is_ext_shared]
    end
  end

  def page_of_remote_channels(cursor)
    team.slack_client.conversations_list \
      types: "public_channel",
      exclude_archived: true,
      cursor:,
      limit: 200
  end

  def base_attributes(channel)
    {
      team:,
      rid: channel[:id]
    }
  end

  def syncable_attributes(channel)
    {
      name: channel[:name],
      shared: channel[:is_shared],
      initial_member_count: channel[:num_members]
    }.compact
  end
end
