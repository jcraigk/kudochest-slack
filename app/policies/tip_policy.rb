class TipPolicy < ApplicationPolicy
  def index?
    profile.admin?
  end

  def destroy?
    record.team == profile.team && profile.admin?
  end
end
