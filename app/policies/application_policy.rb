class ApplicationPolicy
  attr_reader :profile, :record

  def initialize(profile, record)
    @profile = profile
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :profile, :scope

    def initialize(profile, scope)
      @profile = profile
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
