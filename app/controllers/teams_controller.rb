class TeamsController < ApplicationController
  before_action :remember_section, only: %i[edit update]

  def edit
    authorize current_team
    prepare_exempt_profile_options
  end

  def update
    authorize current_team
    params[:team][:import_file].present? ? handle_import : update_team_attrs
  end

  def reset_stats
    authorize current_team
    TeamResetWorker.perform_async(current_team.id)
    redirect_to app_settings_path(section: "danger_zone"), notice: t("teams.reset_requested")
  end

  def export_data
    authorize current_team
    DataExportWorker.perform_async(current_team.id, current_profile.email)
    redirect_to app_settings_path(section: :data),
                notice: t("teams.export_data_requested", email: current_profile.email)
  end

  def leaderboard_page
    return if current_profile.blank?
    @leaderboard = LeaderboardPageService.call \
      team: current_profile.team,
      offset: params[:offset].to_i,
      count: params[:count].to_i
    return if @leaderboard.profiles.blank?
    render partial: "profiles/tiles/leaderboard_rows",
           locals: { leaderboard: @leaderboard, profile: current_profile }
  end

  def uninstall
    authorize current_team
    current_team.uninstall!
    redirect_to app_settings_path(section: "danger_zone"), notice: t("teams.uninstalled")
  end

  private

  def update_team_attrs
    update_exempt_profiles
    update_admin_profiles
    current_team.update(platform_team_params) ? update_success : update_fail
  end

  def handle_import
    flash[:notice] = CsvImporter.call \
      team: current_team,
      text: params[:team][:import_file].read
    redirect_to app_settings_path
  end

  def update_exempt_profiles
    profile_rids = (params[:exempt_profile_rids].presence || "").split(":")
    current_team.profiles
                .where.not(rid: profile_rids)
                .where(throttle_exempt: true)
                .update_all(throttle_exempt: false) # rubocop:disable Rails/SkipsModelValidations
    current_team.profiles
                .where(rid: profile_rids, throttle_exempt: false)
                .update_all(throttle_exempt: true) # rubocop:disable Rails/SkipsModelValidations
  end

  def update_admin_profiles # rubocop:disable Metrics/AbcSize
    profile_rids = (params[:admin_profile_rids].presence || "").split(":")
    profile_rids << current_profile.rid # Always include current user
    current_team.profiles
                .where.not(rid: profile_rids)
                .where(admin: true)
                .update_all(admin: false) # rubocop:disable Rails/SkipsModelValidations
    current_team.profiles
                .where(rid: profile_rids, admin: false)
                .update_all(admin: true) # rubocop:disable Rails/SkipsModelValidations
  end

  def prepare_exempt_profile_options
    @team_profile_options = active_profiles.map do |profile|
      {
        label: profile.long_name,
        value: profile.rid
      }
    end
    @exempt_profile_rids = active_profiles.select(&:throttle_exempt?).map(&:rid)
    @admin_profile_rids = active_profiles.select(&:admin?).map(&:rid)
  end

  def active_profiles
    @active_profiles ||= current_team.profiles.active.all
  end

  def team_params
    params.require(:team).permit \
      :throttled, :throttle_period, :throttle_quantity, :hint_frequency,
      :hint_channel_rid, :max_points_per_tip, :tip_notes, :show_channel, :enable_levels,
      :level_curve, :enable_emoji, :enable_thumbsup, :max_level, :max_level_points,
      :response_mode, :response_theme, :log_channel_rid, :point_emoji, :jab_emoji, :ditto_emoji,
      :enable_streaks, :streak_duration, :streak_reward, :time_zone, :weekly_report,
      :split_tip, :join_channels, :enable_cheers, :enable_loot,
      :enable_jabs, :deduct_jabs, :enable_topics, :require_topic, :show_note, work_days: []
  end

  def platform_team_params
    case current_team.platform
    when "slack" then team_params
    end
  end

  def update_success
    flash[:notice] = t("teams.update_success", platform: current_team.platform.titleize)
    redirect_to app_settings_path
  end

  def update_fail
    prepare_exempt_profile_options
    flash.now[:alert] = t("teams.update_fail", msg: current_team.errors.full_messages.to_sentence)
    render :edit
  end

  def remember_section
    session[:section] = params[:section] if params[:section]
  end
end
