class TopicPolicy < ApplicationPolicy
  def index?
    profile.admin?
  end

  def new?
    profile.admin?
  end

  def create?
    profile.admin?
  end

  def edit?
    team_admin?
  end

  def update?
    team_admin?
  end

  def destroy?
    team_admin?
  end

  private

  def team_admin?
    profile.team == record.team && profile.admin?
  end
end
