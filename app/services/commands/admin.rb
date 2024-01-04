class Commands::Admin < Commands::Base
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include EntityReferenceHelper
  include PointsHelper

  def call
    respond_success
  end

  private

  def respond_success
    ChatResponse.new(mode: :private, text: response_text)
  end

  def base_text
    <<~TEXT.chomp
      #{throttle_points_text}
      #{topic_text}
      #{notes_text}
      #{jab_text}
      #{emoji_text}
      #{level_text}
      #{streak_text}
      #{time_text}
      #{footer_text}
    TEXT
  end

  def footer_text
    str = ''
    str += "*Log channel:* #{channel_link(team.log_channel_rid)}\n" if team.log_channel_rid.present?
    str + "*Admin(s):* #{admin_links}"
  end

  def jab_text
    str = "*#{App.jabs_term.titleize} enabled:* #{boolean_str(team.enable_jabs?)}"
    return str unless team.enable_jabs?
    str + "\n*Deduct #{App.jabs_term}:* #{boolean_str(team.deduct_jabs?)}"
  end

  def topic_text
    str = "*Topics enabled:* #{boolean_str(team.enable_topics?)}"
    return str unless team.enable_topics?
    str += "\n*Topic required:* #{boolean_str(team.require_topic?)}"
    str + "\n*Active topics:* #{team.topics.active.count}"
  end

  def notes_text
    "*Notes:* #{team.tip_notes.titleize}"
  end

  def time_text
    <<~TEXT.chomp
      *Time zone:* #{long_time_zone}
      *Work days:* #{work_days}
    TEXT
  end

  def emoji_text
    str = "*Emoji enabled:* #{boolean_str(team.enable_emoji?)}"
    return str unless team.enable_emoji?

    str += point_emoji
    str += jab_emoji
    str += ditto_emoji
    str
  end

  def point_emoji
    "\n*#{App.points_term.titleize} emoji:* #{team.point_emoj}"
  end

  def jab_emoji
    return '' unless team.enable_jabs?
    "\n*#{App.jab_term.titleize} emoji:* #{team.jab_emoj}"
  end

  def ditto_emoji
    "\n*Ditto emoji:* #{team.ditto_emoj}"
  end

  def level_text
    txt = "*Leveling enabled:* #{boolean_str(team.enable_levels?)}"
    return txt unless team.enable_levels?
    txt + level_detail_text
  end

  def level_detail_text
    <<~TEXT.chomp

      *Maximum level:* #{team.max_level}
      *Required for max level:* #{points_format(team.max_level_points, label: true)}
      *Progression curve:* #{team.level_curve.titleize}
    TEXT
  end

  def throttle_points_text
    str =
      if team.throttled?
        "#{team.throttle_quantity} #{App.points_term} per #{team.throttle_period}"
      else
        'Disabled'
      end
    "*Throttle:* #{str}"
  end

  def streak_text
    txt = "*Giving streaks enabled:* #{boolean_str(team.enable_streaks?)}"
    return txt unless team.enable_streaks?
    txt + <<~TEXT.chomp

      *Giving streak duration:* #{pluralize(team.streak_duration, 'day')}
      *Giving streak reward:* #{points_format(team.streak_reward, label: true)}
    TEXT
  end

  def boolean_str(val)
    val ? 'Yes' : 'No'
  end

  def work_days
    team.work_days.map(&:titleize).join(', ')
  end

  def admin_links
    team.profiles.admin.order(display_name: :asc).map(&:link).join(', ')
  end

  def long_time_zone
    ActiveSupport::TimeZone.all.find { |tz| tz.name == team.time_zone }.to_s
  end
end
