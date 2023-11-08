class ClaimPolicy
  attr_reader :profile, :claim

  def initialize(profile, claim)
    @profile = profile
    @claim = claim
  end

  def index?
    profile.owned_team.present?
  end

  def show?
    viewable?
  end

  def edit?
    profile_owns_team?
  end

  def update?
    profile_owns_team?
  end

  def destroy?
    claim.fulfilled_at.blank? && mine_or_team_admin?
  end

  private

  def mine_or_team_admin?
    profile_owns_claim? || profile_owns_team?
  end

  def profile_owns_team?
    claim.reward.team.owner == profile
  end

  def profile_owns_claim?
    claim.profile == profile
  end
end
