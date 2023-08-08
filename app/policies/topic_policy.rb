class TopicPolicy
  attr_reader :user, :topic

  def initialize(user, topic)
    @user = user
    @topic = topic
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
    topic.team.owning_user == user
  end
end
