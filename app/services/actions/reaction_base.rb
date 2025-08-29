class Actions::ReactionBase < Actions::Base
  protected

  def message_ts
    @message_ts ||= params[:message_ts]
  end

  def event_ts
    @event_ts ||= "#{message_ts}-#{source}#{topic_suffix}-#{profile.id}"
  end

  def thumbsup_regex
    @thumbsup_regex ||= Regexp.new(App.thumbsup_emoji_patterns.join("|"))
  end

  def source
    return "point_reaction" if emoji == team.point_emoji || thumbsup_emoji?
    case emoji
    when team.jab_emoji then "jab_reaction"
    when team.ditto_emoji then "ditto_reaction"
    else "topic_reaction"
    end
  end

  def topic_suffix
    return if topic_id.blank?
    "-topic_id_#{topic_id}"
  end

  def topic_id
    @topic_id ||= team.config[:topics].find { |topic| topic[:emoji] == emoji }&.dig(:id)
  end

  def process_emoji?
    thumbsup_emoji? || standard_emoji? || topic_emoji?
  end

  def standard_emoji?
    team&.enable_emoji? &&
      emoji.in?([ team.point_emoji, team.jab_emoji, team.ditto_emoji ])
  end

  def thumbsup_emoji?
    team&.enable_thumbsup? && thumbsup_regex.match?(emoji)
  end

  def topic_emoji?
    team.enable_topics? && topic_id.present?
  end

  def emoji
    @emoji ||= params[:event][:reaction]
  end
end
