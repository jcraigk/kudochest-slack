class LeaderboardRefreshWorker
  include Sidekiq::Worker

  PAGE_SIZE = 100
  CACHE_TTL = 1.hour

  attr_reader :team_id, :giving_board, :jab_board

  def perform(team_id, giving_board = false, jab_board = false)
    @team_id = team_id
    @giving_board = giving_board
    @jab_board = jab_board

    refresh_leaderboard_pages
    update_metadata
  end

  private

  def refresh_leaderboard_pages
    total_pages.times do |page_num|
      page = page_num + 1
      profiles = fetch_page(page)
      cache_page(page, profiles)
    end
  end

  def fetch_page(page)
    result = LeaderboardQueryService.call(
      team: team,
      giving_board: giving_board,
      jab_board: jab_board,
      page: page,
      per_page: PAGE_SIZE
    )

    format_profiles(result[:profiles])
  end

  def format_profiles(profiles)
    profiles.map do |prof|
      # Handle both ActiveRecord objects and OpenStruct from tests
      rank_value = if prof.respond_to?(:attributes) && prof.attributes
                     prof.attributes["rank"]
      elsif prof.respond_to?(:rank)
                     prof.rank
      else
                     nil
      end

      LeaderboardProfile.new(
        id: prof.id,
        rank: rank_value,
        previous_rank: rank_value, # TODO: Track previous ranks
        slug: prof.slug,
        link: prof.dashboard_link,
        display_name: prof.display_name,
        real_name: prof.real_name,
        points: prof.send(value_col),
        last_timestamp: prof.send(last_timestamp_col).to_i,
        avatar_url: prof.avatar_url
      )
    end
  end

  def cache_page(page, profiles)
    cache.set_page(page, profiles)
  end

  def update_metadata
    metadata = {
      updated_at: Time.current.to_i,
      total_pages: total_pages,
      total_profiles: total_count,
      page_size: PAGE_SIZE
    }

    cache.set_metadata(metadata)
  end

  def cache
    @cache ||= Cache::Leaderboard.new(team_id, giving_board, jab_board)
  end

  def total_pages
    @total_pages ||= (total_count.to_f / PAGE_SIZE).ceil
  end

  def total_count
    @total_count ||= LeaderboardQueryService.call(
      team: team,
      giving_board: giving_board,
      jab_board: jab_board,
      page: 1
    )[:total_count]
  end


  def value_col
    @value_col ||=
      if giving_board
        jab_board ? :jabs_sent : :points_sent
      elsif jab_board
        :jabs_received
      else
        team.deduct_jabs? ? :balance : :points_received
      end
  end

  def verb
    @verb ||= giving_board ? "sent" : "received"
  end

  def last_timestamp_col
    @last_timestamp_col ||= "last_tip_#{verb}_at"
  end


  def team
    @team ||= Team.find(team_id)
  end
end
