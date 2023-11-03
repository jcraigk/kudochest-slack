class TipPolicy
  attr_reader :user, :tip

  def initialize(user, tip)
    @user = user
    @tip = tip
  end

  def index?
    user.owned_team.present?
  end

  def destroy?
    tip.from_profile.team.owner == user
  end
end
