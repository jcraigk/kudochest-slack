class Actions::ReactionAdded < Actions::ReactionBase
  DITTO_SOURCES = %w[
    modal inline point_reaction jab_reaction ditto_reaction topic_reaction reply
  ].freeze

  def call
    return unless process_emoji?
    process_reaction_and_respond
  end

  private

  def process_reaction_and_respond
    TipMentionService.call \
      profile:,
      mentions:,
      source:,
      event_ts:,
      message_ts:,
      channel_rid: params[:channel_rid],
      channel_name:
  end

  def mentions
    case source
    when "ditto_reaction" then ditto_mentions
    when "point_reaction", "jab_reaction", "topic_reaction" then [ author_mention ]
    end
  end

  def ditto_mentions
    ditto_tips.map do |tip|
      Mention.new \
        rid: "#{App.prof_prefix}#{tip.to_profile.rid}",
        topic_id: tip.topic_id,
        quantity: tip.quantity
    end
  end

  def ditto_tips
    @ditto_tips ||=
      Tip.where(source: DITTO_SOURCES)
         .includes(:to_profile)
         .where(event_ts: message_ts)
         .where.not(to_profile: profile)
         .or(response_ts_tips)
  end

  def response_ts_tips
    Tip.where(source: DITTO_SOURCES)
       .where(response_ts: message_ts)
       .where.not(to_profile: profile)
  end

  def author_mention
    Mention.new \
      rid: "#{App.prof_prefix}#{author_profile_rid}",
      topic_id:,
      quantity: reaction_quantity
  end

  def reaction_quantity
    default_quantity = team.default_reaction_point_quantity
    source == "jab_reaction" ? (0 - default_quantity) : default_quantity
  end

  def author_profile_rid
    params.dig(:event, :item_user) || params[:to_profile_rid]
  end

  def channel_name
    params[:channel_name].presence || channel&.name
  end

  # Must fetch since channel_name is not provided by Slack Event callback
  def channel
    @channel ||= Channel.find_with_team(params[:team_rid], params[:channel_rid])
  end
end
