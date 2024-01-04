class BonusPolicy < ApplicationPolicy
  def index?
    profile.admin?
  end

  def create?
    profile.admin?
  end
end
