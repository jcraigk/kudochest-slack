module ProfileDecorator
  include PointsHelper
  extend ActiveSupport::Concern

  def helpers
    ActionController::Base.helpers
  end

  def link
    "<#{PROF_PREFIX}#{rid}>"
  end

  def link_with_stat
    team.enable_levels? ? link_with_level : link_with_points(label: false)
  end

  def link_with_level
    "#{link} (level #{level})"
  end

  def link_with_points(label: true)
    "#{link} (#{points_format(total_points, label:)})"
  end

  def dashboard_link
    case team.platform.to_sym
    when :slack then "<#{web_url}|#{display_name}>"
    end
  end

  def dashboard_link_with_stat
    case team.platform.to_sym
    when :slack then "<#{web_url}|#{display_name} (#{points_format(total_points, humanize: true)})>"
    when :web then web_profile_link
    end
  end

  def webref
    helpers.tag.span(display_name, class: 'chat-ref')
  end

  def webref_with_stat
    team.enable_levels? ? webref_with_level : webref_with_points
  end

  def webref_with_level
    "#{webref} (level #{level})"
  end

  def webref_with_points
    "#{webref} (#{points_format(total_points, label: true)})"
  end

  def long_name
    str = display_name
    str += " (#{real_name})" if display_name != real_name
    str
  end

  def next_level_points_sentence
    return 'max level' if max_level?
    "#{points_format(points_remaining_until_next_level, label: true)} until level #{level + 1}"
  end

  def points_remaining_until_next_level
    return 0 if max_level?
    points_required_for_next_level - total_points
  end

  def points_required_for_next_level
    LevelToPointsService.call(team:, level: next_level)
  end

  def points_required_for_current_level
    LevelToPointsService.call(team:, level:)
  end

  def level
    PointsToLevelService.call(team:, points: total_points)
  end

  def next_level
    [level + 1, team.max_level].min
  end

  def max_level?
    level == team.max_level
  end

  def active_streak
    @active_streak ||= streak_date && next_streak_date >= today ? streak_count : 0
  end

  def active_streak_sentence
    str = helpers.pluralize(active_streak, 'day')
    return str if active_streak.zero?
    str + ", next target #{next_streak_date.strftime('%b %-d')} (#{next_streak_date_distance})"
  end

  def rank
    @rank ||= LeaderboardPageService.call(profile: self, count: 1)&.profiles&.first&.rank
  end

  def next_streak_date
    @next_streak_date ||= calculate_next_streak_date
  end

  def next_streak_date_distance
    Time.use_zone(team.time_zone) do
      case next_streak_date
      when today then 'today'
      when tomorrow then 'tomorrow'
      else "on #{next_streak_date.strftime('%A')}"
      end
    end
  end

  def web_url
    "#{App.base_url}/profiles/#{slug}"
  end

  def web_profile_link
    case team.response_theme.to_sym
    when :quiet, :quiet_stat, :basic then webref
    when :fancy then webref_with_stat
    end
  end

  def points_unclaimed
    points_received - points_claimed
  end

  def total_points
    team.deduct_jabs? ? balance : points
  end

  private

  def calculate_next_streak_date
    return today unless (date = streak_date)
    loop do
      date = date.advance(days: 1)
      return date if working_day?(date)
    end
  end

  def working_day?(date)
    date.strftime('%A').downcase.in?(team.work_days)
  end

  def today
    @today ||= Time.use_zone(team.time_zone) { Time.zone.today }
  end

  def tomorrow
    @tomorrow ||= Time.use_zone(team.time_zone) { Time.zone.tomorrow }
  end
end
