class LeaderboardQueryService < Base::Service
  PAGE_SIZE = 100

  option :team
  option :giving_board, default: proc { false }
  option :jab_board, default: proc { false }
  option :page, default: proc { 1 }
  option :per_page, default: proc { PAGE_SIZE }

  def call
    {
      profiles: ranked_profiles,
      total_count: total_count,
      page: page,
      per_page: per_page
    }
  end

  private

  def ranked_profiles
    query = Profile
      .select(profiles_with_rank_sql)
      .where(team_id: team.id, deleted: false)
      .where.not(last_timestamp_col => nil)
      .where("profiles.#{value_col} > 0")
      .order("profiles.#{value_col} DESC, profiles.#{last_timestamp_col} DESC, profiles.display_name ASC")
      .limit(per_page)
      .offset((page - 1) * per_page)

    query
  end

  def profiles_with_rank_sql
    <<~SQL
      profiles.*,
      DENSE_RANK() OVER (
        ORDER BY profiles.#{value_col} DESC,
                 profiles.#{last_timestamp_col} DESC,
                 profiles.display_name ASC
      ) as rank
    SQL
  end

  def total_count
    @total_count ||= Profile
      .where(team_id: team.id, deleted: false)
      .where.not(last_timestamp_col => nil)
      .where("profiles.#{value_col} > 0")
      .count
  end

  def value_col
    @value_col ||=
      if giving_board
        jab_board ? "jabs_sent" : "points_sent"
      elsif jab_board
        "jabs_received"
      else
        team.deduct_jabs? ? "balance" : "points_received"
      end
  end

  def last_timestamp_col
    @last_timestamp_col ||= "last_tip_#{verb}_at"
  end

  def verb
    @verb ||= giving_board ? "sent" : "received"
  end
end
