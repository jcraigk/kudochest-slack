class ApplicationPolicy
  attr_reader :profile, :record

  def initialize(profile, record)
    @profile = profile
    @record = record
  end

  class Scope
    def initialize(profile, scope)
      @profile = profile
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :profile, :scope
  end
end
