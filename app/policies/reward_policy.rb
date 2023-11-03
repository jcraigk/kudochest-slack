class RewardPolicy
  attr_reader :user, :reward

  def initialize(user, reward)
    @user = user
    @reward = reward
  end

  def index?
    user.owned_team.present?
  end

  def new?
    user.owned_team.present?
  end

  def create?
    user.owned_team.present?
  end

  def edit?
    user_owns_team?
  end

  def update?
    user_owns_team?
  end

  def destroy?
    user_owns_team?
  end

  private

  def user_owns_team?
    reward.team.owner == user
  end
end
