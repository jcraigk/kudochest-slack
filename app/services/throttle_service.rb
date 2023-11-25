class ThrottleService < Base::Service
  option :profile
  option :quantity

  def call
    [next_available_time, available_quantity]
  end

  private

  def next_available_time
    throttle_exceeded? ? earliest_given_tip.created_at + throttle_days : Time.current
  end

  def available_quantity
    [profile.team.throttle_quantity - recently_given_quantity, 0].max
  end

  def throttle_exceeded?
    profile.team.throttled? && recently_given_quantity >= profile.team.throttle_quantity
  end

  def recently_given_quantity
    Tip.where(from_profile: profile)
       .where('created_at >= ?', throttle_days.ago)
       .sum('ABS(quantity)')
  end

  def earliest_given_tip
    Tip.where(from_profile: profile)
       .where('created_at >= ?', throttle_days.ago)
       .order(created_at: :asc)
       .first
  end

  def throttle_days
    @throttle_days ||= profile.team.throttle_period_days.days
  end
end
