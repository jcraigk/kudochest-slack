class ProfilePolicy
  attr_reader :current_profile, :profile

  def initialize(current_profile, profile)
    @current_profile = current_profile
    @profile = profile
  end

  def show?
    mine? || active_teammate? || current_profile_owns_team?
  end

  def edit?
    mine?
  end

  def update?
    mine?
  end

  private

  def current_profile_owns_team?
    profile.team.owner == current_profile
  end

  def mine?
    current_profile == profile
  end

  def active_teammate?
    profile.active? && profile.team == current_profile.profile.team
  end
end
