class ProfilePolicy < ApplicationPolicy
  def show?
    mine? || active_teammate? || profile.admin?
  end

  def edit?
    mine?
  end

  def update?
    mine?
  end

  private

  def mine?
    profile == record
  end

  def active_teammate?
    record.active? && record.team == profile.team
  end
end
