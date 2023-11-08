class TopicPolicy
  attr_reader :profile, :topic

  def initialize(profile, topic)
    @profile = profile
    @topic = topic
  end

  def index?
    profile.owned_team.present?
  end

  def new?
    profile.owned_team.present?
  end

  def create?
    profile.owned_team.present?
  end

  def edit?
    profile_owns_team?
  end

  def update?
    profile_owns_team?
  end

  def destroy?
    profile_owns_team?
  end

  private

  def profile_owns_team?
    topic.team.owner == profile
  end
end
