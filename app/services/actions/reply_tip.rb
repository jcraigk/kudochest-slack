class Actions::ReplyTip < Actions::Base
  def call
    process_tip_mentions
  end

  private

  def process_tip_mentions
    TipMentionService.call \
      profile:,
      mentions:,
      source: "reply",
      event_ts: params[:message_ts],
      channel_rid: params[:channel_rid],
      channel_name: params[:channel_name]
  end

  def mentions
    [ Mention.new(rid: "#{App.prof_prefix}#{params[:message_profile_rid]}", quantity: 1) ]
  end
end
