class ClaimPolicy < ApplicationPolicy
  def index?
    profile.admin?
  end

  def show?
    team_admin?
  end

  def edit?
    team_admin?
  end

  def update?
    team_admin?
  end

  def destroy?
    record.fulfilled_at.blank? && mine_or_team_admin?
  end

  private

  def mine_or_team_admin?
    record.profile == profile? || team_admin?
  end

  def team_admin?
    record.team == profile.team && profile.admin?
  end
end
