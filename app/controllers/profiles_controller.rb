class ProfilesController < ApplicationController
  def show
    @profile = Profile.find_by(slug: params[:id])
    redirect_to dashboard_path if @profile.blank?

    authorize @profile
    build_dashboard_for(@profile)
  end

  def random_showcase
    fetch_showcase_profile
    @leaderboard = LeaderboardPageService.call(profile: @profile)
    @hide_paging = true
    render 'profiles/random_showcase', layout: false
  end

  def update
    authorize current_profile
    if current_profile.update(profile_params)
      flash[:notice] = t('profiles.update_success')
    else
      flash[:alert] = update_fail_msg
    end
    redirect_to user_settings_path
  end

  private

  def update_fail_msg
    t('profiles.update_fail', msg: current_profile.errors.full_messages.to_sentence)
  end

  def fetch_showcase_profile
    last_profile_id = params[:last_profile_id].to_i
    @profile = Profile.active.where(team: current_profile.team)
    @profile = @profile.where.not(id: last_profile_id) if last_profile_id.positive?
    @profile = @profile.order('RANDOM()').first
  end

  def requested_profile
    @requested_profile ||= Profile.find_by(reg_token: params[:reg_token])
  end

  def redirect_to_dashboard(opts)
    redirect_to dashboard_path, opts
  end

  def profile_params
    params.require(:profile).permit \
      :allow_dm, :weekly_report, :announce_tip_sent, :announce_tip_received, :share_history
  end
end
