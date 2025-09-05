class Base::ChannelSyncService < Base::Service
  option :team
  option :new_channel_rid, optional: true

  def call
    sync_active_channels
  end

  private

  def sync_active_channels
    # Mark all existing channels as pending deletion
    team.channels.update_all(updated_at: 1.day.ago)

    batch_size = 50

    fetch_remote_channels.each_slice(batch_size) do |channel_batch|
      Channel.transaction do
        channel_batch.each do |remote_channel|
          base_attrs = base_attributes(remote_channel)
          sync_attrs = syncable_attributes(remote_channel).merge(updated_at: Time.current)

          if (channel = Channel.find_by(base_attrs))
            channel.update!(sync_attrs)
          else
            Channel.create!(base_attrs.merge(sync_attrs))
          end
        end
      end
    end

    # Destroy channels that weren't updated (they don't exist remotely anymore)
    destroy_old_channels
  end

  def destroy_old_channels
    old_channels = team.channels.where("updated_at < ?", 1.hour.ago)

    # Update team if log channel is being removed
    if team.log_channel_rid && old_channels.exists?(rid: team.log_channel_rid)
      team.update!(log_channel_rid: nil)
    end

    old_channels.destroy_all
  end
end
