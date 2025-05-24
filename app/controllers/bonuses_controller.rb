class BonusesController < ApplicationController
  def index
    authorize :bonus
  end

  def create
    authorize :bonus
    BonusCalculatorWorker.perform_async(worker_args.to_json)
    redirect_to \
      bonuses_path, notice: t("bonuses.calculation_requested", email: current_profile.email)
  end

  private

  def worker_args # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    {
      team_id: current_team.id,
      start_date: params[:start_date],
      end_date: params[:end_date],
      include_streak_points: params[:include_streak_points],
      include_imported_points: params[:include_imported_points],
      style: params[:style],
      pot_size: params[:pot_size],
      dollar_per_point: params[:dollar_per_point],
      email: current_profile.email
    }
  end
end
