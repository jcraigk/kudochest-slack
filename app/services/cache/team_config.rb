class Cache::TeamConfig < Base::Service
  param :platform
  param :rid

  def call
    cached_data
  end

  def delete
    Rails.cache.delete(cache_key)
  end

  private

  def cached_data
    JSON.parse(cached_json, symbolize_names: true)
        .each_with_object({}) { |(k, v), h| h[k] = coerce_value(k, v) }
  end

  def coerce_value(attr, value)
    case Team.columns_hash[attr.to_s]&.type
    when :integer then value.to_i
    when :decimal then BigDecimal(value.presence || '0')
    else value; end
  end

  def cached_json
    Rails.cache.fetch(cache_key) { json_data }
  end

  def json_data
    team.attributes
        .slice(*Team::CONFIG_ATTRS)
        .merge(topics: topic_data)
        .merge(regex:)
        .to_json
  end

  def topic_data
    team.topics.active.order(name: :asc).map do |topic|
      topic.attributes.slice('id', 'name', 'keyword', 'emoji').symbolize_keys
    end
  end

  def team
    @team ||= Team.includes(:topics).find_by!(platform:, rid:)
  end

  def cache_key
    "config/#{platform}/#{rid}"
  end

  def regex
    "(?<match>#{mention}#{spaces}#{triggers}#{spaces}#{topic_keywords})"
  end

  def mention # rubocop:disable Metrics/MethodLength
    <<~TEXT.gsub(/\s+/, '')
      (?:
        <
          (?<entity_rid>
            (?:
              #{Regexp.escape(PROFILE_PREFIX[platform])}
              |
              #{Regexp.escape(CHAN_PREFIX)}
              |
              #{Regexp.escape(SUBTEAM_PREFIX[platform])}
            )
            #{RID_CHARS[platform]}+
          )
          (?:#{LEGACY_SLACK_SUFFIX_PATTERN})?
        >
        |
        #{group_keyword_pattern[platform]}
      )
    TEXT
  end

  def triggers
    "#{quantity_prefix}(?:#{inlines}|#{emojis})#{quantity_suffix}"
  end

  def inlines
    patterns = POINT_INLINES.map { |str| Regexp.escape(str) }
    patterns << JAB_INLINES.map { |str| Regexp.escape(str) } if team.enable_jabs?
    "(?<inlines>#{patterns.join('|')})"
  end

  def emojis
    patterns = emoji_patterns.map { |str| ":#{str}:" }
    str = patterns.join('|').presence || 'no-emoji'
    "(?<emojis>(?:(?:#{str})\\s*)+)"
  end

  def emoji_patterns
    return [] unless team.enable_emoji?
    emojis = [team.point_emoji]
    emojis << team.jab_emoji if team.enable_jabs?
    emojis += team.topics.pluck(:emoji) if team.enable_topics?
    emojis
  end

  def quantity_prefix
    '(?<prefix_quantity>\d+\.?\d*)?\s?'
  end

  def quantity_suffix
    '\s?(?<suffix_quantity>\d+\.?\d*)?'
  end

  def spaces
    '\s{0,20}'
  end

  def group_keyword_pattern
    {
      slack: '<!(?<group_keyword>everyone|channel|here)>'
    }
  end

  def topic_keywords
    words = team.topics&.pluck(:keyword) || []
    "(?<topic_keywords>#{(words + topic_emojis)&.join('|')})?"
  end

  def topic_emojis
    team.topics&.pluck(:emoji)&.map { |e| ":#{e}:" } || []
  end
end
