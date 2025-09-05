class Cache::Leaderboard < Base::Service
  PAGE_TTL = 1.hour

  param :team_id
  param :giving_board, default: -> { false }
  param :jab_board, default: -> { false }

  def get_page(page)
    data = REDIS.get(page_key(page))
    return nil if data.blank?

    JSON.parse(data, symbolize_names: true).map { |p| LeaderboardProfile.new(p) }
  end

  def set_page(page, profiles)
    REDIS.setex(page_key(page), PAGE_TTL, profiles.to_json)
  end

  def get_metadata
    data = REDIS.get(metadata_key)
    return nil if data.blank?

    JSON.parse(data, symbolize_names: true)
  end

  def set_metadata(metadata)
    REDIS.setex(metadata_key, PAGE_TTL, metadata.to_json)
  end

  def delete_all_pages
    keys = REDIS.keys("#{base_key}/page:*")
    REDIS.del(*keys) if keys.any?
  end

  private

  def page_key(page)
    "#{base_key}/page:#{page}"
  end

  def metadata_key
    "#{base_key}/metadata"
  end

  def base_key
    "leaderboard/#{team_id}/#{style}/#{action}"
  end

  def action
    giving_board ? "sent" : "received"
  end

  def style
    jab_board ? "jabs" : "points"
  end
end
