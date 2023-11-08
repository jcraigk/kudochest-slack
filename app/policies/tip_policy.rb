class TipPolicy
  attr_reader :profile, :tip

  def initialize(profile, tip)
    @profile = profile
    @tip = tip
  end

  def index?
    profile.owned_team.present?
  end

  def destroy?
    tip.from_profile.team.owner == profile
  end
end
