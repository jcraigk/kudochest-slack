class LeaderboardPageService < Base::Service
  option :team, default: proc { }
  option :profile, default: proc { }
  option :count, default: proc { App.default_leaderboard_size }
  option :offset, default: proc { }
  option :giving_board, default: proc { false }
  option :jab_board, default: proc { false }

  attr_accessor :offset

  def call
    @team ||= profile&.team
    @count = 1_000 if count == "all"

    return nil if metadata.blank?

    fetch_leaderboard_data
  end

  private

  def fetch_leaderboard_data
    if offset.present?
      fetch_by_offset
    else
      fetch_contextual
    end
  end

  def fetch_by_offset
    profiles = []
    start_page = (offset / LeaderboardRefreshWorker::PAGE_SIZE) + 1
    end_offset = offset + count - 1
    end_page = (end_offset / LeaderboardRefreshWorker::PAGE_SIZE) + 1

    (start_page..end_page).each do |page|
      page_profiles = cache.get_page(page)
      next if page_profiles.blank?

      profiles.concat(page_profiles)
    end

    start_idx = offset % LeaderboardRefreshWorker::PAGE_SIZE
    end_idx = start_idx + count - 1

    LeaderboardPage.new(metadata[:updated_at], profiles[start_idx..end_idx])
  end

  def fetch_contextual
    profile_page = find_profile_page
    return fetch_page_centered_on_profile(profile_page) if profile_page

    # Default to first page if no profile context
    @offset = 0
    fetch_by_offset
  end

  def find_profile_page
    (1..metadata[:total_pages]).each do |page|
      profiles = cache.get_page(page)
      next if profiles.blank?

      return page if profiles.any? { |p| p.slug == profile&.slug }
    end
    nil
  end

  def fetch_page_centered_on_profile(center_page)
    profiles = []
    pages_needed = (count.to_f / LeaderboardRefreshWorker::PAGE_SIZE).ceil
    start_page = [ 1, center_page - (pages_needed / 2) ].max
    end_page = [ start_page + pages_needed - 1, metadata[:total_pages] ].min

    (start_page..end_page).each do |page|
      page_profiles = cache.get_page(page)
      profiles.concat(page_profiles) if page_profiles.present?
    end

    profile_idx = profiles.index { |p| p.slug == profile&.slug } || 0
    start_idx = [ 0, profile_idx - (count / 2) ].max
    end_idx = [ start_idx + count - 1, profiles.length - 1 ].min

    LeaderboardPage.new(metadata[:updated_at], profiles[start_idx..end_idx])
  end

  def metadata
    @metadata ||= cache.get_metadata
  end

  def cache
    @cache ||= Cache::Leaderboard.new(team.id, giving_board, jab_board)
  end
end
