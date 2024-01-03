class TeamPolicy
  attr_reader :profile, :team

  def initialize(profile, team)
    @profile = profile
    @team = team
  end

  def index?
    profile_owns_team?
  end

  def stripe_checkout_start?
    profile_owns_team?
  end

  def stripe_cancel?
    profile_owns_team?
  end

  def edit?
    profile_owns_team?
  end

  def update?
    profile_owns_team?
  end

  def reset_stats?
    profile_owns_team?
  end

  def uninstall?
    profile_owns_team?
  end

  def join_all_channels?
    profile_owns_team?
  end

  # def join_specific_channels?
  #   profile_owns_team?
  # end

  def skip_join_channels?
    profile_owns_team?
  end

  def export_data?
    profile_owns_team?
  end

  def confirm_emoji_added?
    profile_owns_team?
  end

  def skip_emoji?
    profile_owns_team?
  end

  private

  def profile_owns_team?
    team.owner == profile
  end
end
