class TipMentionService < Base::Service
  option :channel_name
  option :channel_rid
  option :event_ts
  option :message_ts, default: -> { }
  option :mentions
  option :profile
  option :source

  attr_reader :tips

  def call
    return respond_throttle_exceeded if throttle_exceeded?
    return respond_note_required if required_note_missing?

    @tips = []
    Tip.transaction do
      create_tips
      TipOutcomeService.call(tips:)
    end

    tips.any? ? respond_success : respond_no_action
  rescue StandardError => e
    handle_error(e)
  end

  private

  def handle_error(exception)
    klass = exception.class.name
    raise exception unless klass.start_with?("ActiveRecord::")
    message = exception.message
    case klass
    when "ActiveRecord::RecordNotUnique" then return # message = 'Duplicate request ignored'
    when "ActiveRecord::RecordInvalid" then message.gsub!("Validation failed: ", "")
    end
    respond_error(message)
  end

  def respond_success
    return ChatResponse.new(mode: :silent) unless profile.announce_tip_sent?
    ChatResponse.new \
      mode: :public,
      response:,
      tips:, # TODO: We shouldn't need to pass all this data
      image: response_image
  end

  def respond_error(message)
    ChatResponse.new \
      mode: :error,
      text: t("errors.generic_personalized", user: profile.link, message:)
  end

  def respond_no_action
    ChatResponse.new \
      mode: :error,
      text: I18n.t("errors.no_tips", user: profile.display_name)
  end

  def create_tips
    @tips = uniq_entity_mentions.map do |mention|
      next if mention.profiles.none?
      create_tips_for(mention)
    end.flatten.compact
  end

  def create_tips_for(mention) # rubocop:disable Metrics/MethodLength
    TipFactory.call \
      topic_id: mention.topic_id,
      event_ts:,
      message_ts:,
      from_channel_name: channel_name,
      from_channel_rid: channel_rid,
      from_profile: profile,
      note: mention.note,
      quantity: mention.quantity,
      source:,
      to_entity: mention.entity,
      to_profiles: mention.profiles,
      timestamp:
  end

  def timestamp
    @timestamp ||= Time.current
  end

  def response_image
    return unless team.response_theme.start_with?("gif") && tips.any?
    ResponseImageService.call \
      type: "tip",
      config: team.config,
      fragments: response.image_fragments,
      tips:
  end

  def response
    @response = TipResponseService.call(tips:)
  end

  def respond_throttle_exceeded
    ChatResponse.new(mode: :error, text: throttle_error)
  end

  def respond_note_required
    ChatResponse.new(mode: :error, text: I18n.t("tips.note_required"))
  end

  def fetch_entity(rid)
    if rid.in?(%w[everyone here]) then rid
    elsif rid.in?(%w[channel]) then channel_entity(channel_rid.delete(CHAN_PREFIX))
    elsif rid.start_with?(*SUBTEAM_PREFIX.values) then subteam_entity(rid)
    elsif rid.start_with?(PROF_PREFIX) then profile_entity(rid)
    elsif rid.start_with?(CHAN_PREFIX) then channel_entity(rid)
    end
  end

  def channel_entity(rid)
    rid = rid.delete(CHAN_PREFIX)
    Channel.find_with_team(team.rid, rid) || Channel.new(name: channel_name, rid:)
  end

  def profile_entity(rid)
    Profile.find_with_team(team.rid, rid.delete(PROFILE_PREFIX[:slack]))
  end

  def subteam_entity(rid)
    raw_rid = rid.gsub(SUBTEAM_PREFIX[:slack], "")
    Subteam.find_with_team(team.rid, raw_rid)
  end

  def profiles_for_entity(entity)
    return team.profiles.active.where.not(rid: profile.rid) if entity == "everyone"
    return channel_profiles(channel_rid, here: true) if entity == "here"
    case entity.class.name
    when "Profile" then [ entity ]
    when "Subteam" then subteam_profiles(entity)
    when "Channel" then channel_profiles(entity.rid)
    end
  end

  def channel_profiles(channel_rid, here: false)
    "#{team.plat}::ChannelMemberService".constantize.call(
      team:,
      channel_rid:,
      here:
    ).reject { |prof| prof.id == profile.id }
  end

  def subteam_profiles(subteam)
    subteam.profiles.active.where.not(id: profile.id).to_a
  end

  def uniq_entity_mentions
    return [ everyone_mention ] if everyone_mention.present?
    return [ here_mention ] if here_mention.present?

    # Ensure each profile is mentioned only once, preferring
    # Direct mention, then subteam, then channel
    profile_mentions + sanitized_subteam_mentions + sanitized_channel_mentions
  end

  def profile_mentions
    @profile_mentions ||= entity_mentions.select { |m| m.entity.is_a?(Profile) }
  end

  def everyone_mention
    @everyone_mention ||= entity_mentions.find { |m| m.entity == "everyone" }
  end

  def here_mention
    @here_mention ||= entity_mentions.find { |m| m.entity == "here" }
  end

  def channel_mention
    @channel_mention ||= entity_mentions.find { |m| m.entity == "channel" }
  end

  def sanitized_channel_mentions
    channel_mentions.map do |mention|
      mention.tap do |m|
        m.profiles.reject! { |prof| prof.rid.in?(profile_mention_rids + subteam_mention_rids) }
      end
    end
  end

  def sanitized_subteam_mentions
    subteam_mentions.map do |mention|
      mention.tap do |m|
        m.profiles.reject! { |prof| prof.rid.in?(profile_mention_rids) }
      end
    end
  end

  def profile_mention_rids
    @profile_mention_rids ||= profile_mentions.map { |m| m.entity.rid }
  end

  def subteam_mention_rids
    @subteam_mention_rids ||= subteam_mentions.map { |x| x.entity.profiles }.flatten.map(&:rid)
  end

  def subteam_mentions
    @subteam_mentions ||= entity_mentions.select { |m| m.entity.is_a?(Subteam) }
  end

  def channel_mentions
    @channel_mentions ||= entity_mentions.select { |m| m.entity.is_a?(Channel) }
  end

  def entity_mentions
    @entity_mentions ||= mentions.filter_map do |mention|
      next unless (entity = fetch_entity(mention.rid))
      EntityMention.new \
        entity:,
        profiles: profiles_for_entity(entity),
        topic_id: mention.topic_id,
        quantity: mention.quantity,
        note: mention.note
    end
  end

  def throttle_exceeded?
    return false unless team.throttled? && !profile.throttle_exempt
    calculate_throttle_values
    @available_quantity < quantity_sum
  end

  def calculate_throttle_values
    @next_throttle_time, @available_quantity =
      ThrottleService.call(profile:, quantity: quantity_sum)
  end

  def throttle_error
    phrase = distance_of_time_in_words(Time.current, @next_throttle_time)
    ":#{App.error_emoji}: Sorry #{profile.link}, you must wait #{phrase} to " \
      "give more #{throttle_fragment}"
  end

  def throttle_fragment
    if @available_quantity == 1
      "than a #{App.point_term}"
    elsif @available_quantity > 1
      "than #{@available_quantity} #{App.points_term}"
    else
      App.points_term
    end
  end

  def quantity_sum
    @quantity_sum ||= entity_mentions.sum { |m| mention_quantity(m).abs }
  end

  def mention_quantity(mention)
    quantity = mention.quantity
    num_profiles = mention.profiles.size
    if team.split_tip?
      (quantity / num_profiles.to_f).floor.to_i
    else
      quantity * num_profiles
    end
  end

  def required_note_missing?
    team.tip_notes.required? && mentions.pluck(:note).compact_blank.none?
  end

  def team
    @team ||= profile.team
  end
end
