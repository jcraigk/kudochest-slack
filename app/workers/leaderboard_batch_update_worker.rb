class LeaderboardBatchUpdateWorker
  include Sidekiq::Worker

  UPDATE_INTERVAL = 1.minute

  sidekiq_options unique: :until_executed, unique_args: ->(args) { args }

  def perform(team_id, giving_board = false, jab_board = false)
    if recently_updated?(team_id, giving_board, jab_board)
      # Schedule a delayed update to ensure eventual consistency
      schedule_delayed_update(team_id, giving_board, jab_board)
      return
    end

    LeaderboardRefreshWorker.new.perform(team_id, giving_board, jab_board)
    mark_as_updated(team_id, giving_board, jab_board)
    # Clear any pending delayed update since we just updated
    REDIS.del(delayed_update_key(team_id, giving_board, jab_board))
  end

  private

  def recently_updated?(team_id, giving_board, jab_board)
    last_update = REDIS.get(update_key(team_id, giving_board, jab_board))
    # If never updated, always refresh (for initial population)
    return false if last_update.nil?

    # Check if metadata exists - if not, force refresh
    cache = Cache::Leaderboard.new(team_id, giving_board, jab_board)
    return false if cache.get_metadata.blank?

    Time.current - Time.at(last_update.to_i) < UPDATE_INTERVAL
  end

  def mark_as_updated(team_id, giving_board, jab_board)
    REDIS.setex(update_key(team_id, giving_board, jab_board), UPDATE_INTERVAL, Time.current.to_i)
  end

  def update_key(team_id, giving_board, jab_board)
    type = leaderboard_type(giving_board, jab_board)
    "leaderboard_updated:#{team_id}:#{type}"
  end

  def delayed_update_key(team_id, giving_board, jab_board)
    type = leaderboard_type(giving_board, jab_board)
    "leaderboard_delayed:#{team_id}:#{type}"
  end

  def leaderboard_type(giving_board, jab_board)
    if giving_board
      jab_board ? "jabs_sent" : "points_sent"
    elsif jab_board
      "jabs_received"
    else
      "points_received"
    end
  end

  def schedule_delayed_update(team_id, giving_board, jab_board)
    # Check if we already have a delayed update scheduled
    return if REDIS.get(delayed_update_key(team_id, giving_board, jab_board))

    # Mark that we have a delayed update scheduled
    REDIS.setex(delayed_update_key(team_id, giving_board, jab_board), UPDATE_INTERVAL + 10, "1")

    # Schedule the job to run after the update interval
    LeaderboardBatchUpdateWorker.perform_in(UPDATE_INTERVAL + 5.seconds, team_id, giving_board, jab_board)
  end
end
