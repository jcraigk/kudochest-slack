class NextTokenDisbursalService < Base::Service
  option :team

  def call
    send("next_#{team.token_frequency}")
  end

  private

  def next_weekly
    calculate_next_time(1.week, tolerance: 2.days)
  end

  def next_monthly
    calculate_next_time(1.month)
  end

  def next_quarterly
    calculate_next_time(3.months)
  end

  def next_yearly
    calculate_next_time(1.year)
  end

  def calculate_next_time(interval, tolerance: nil)
    reference_time = now + interval
    next_time = reference_time_day(reference_time)
    if tolerance.present?
      if current_week_time >= now && (current_week_time - now) >= tolerance
        next_time = current_week_time
      end
    elsif next_time <= reference_time
      next_time += 1.week
    end
    next_time
  end

  def now
    Time.current.in_time_zone(team.time_zone)
  end

  def target_day_index
    Date::DAYNAMES.index(team.token_day.capitalize)
  end

  def reference_time_day(reference_time)
    reference_time.beginning_of_week(:sunday)
                  .advance(days: target_day_index, hours: team.action_hour)
  end

  def current_week_time
    now.beginning_of_week(:sunday).advance(days: target_day_index, hours: team.action_hour)
  end
end
