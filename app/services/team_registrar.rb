class TeamRegistrar < Base::Service
  option :platform
  option :rid
  option :name
  option :avatar_url
  option :api_key
  option :installer_profile_rid

  def call
    return false if existing_team&.active?

    register_team
    true
  end

  private

  def register_team
    team = create_or_update_team
    Slack::ChannelSyncService.call(team:)
    Slack::TeamSyncService.call(team:, first_run: true)
    Profile.find_by(rid: installer_profile_rid).update!(admin: true)
  end

  def create_or_update_team
    return existing_team.tap { |team| team.update!(update_attrs) } if existing_team
    Team.create!(new_attrs)
  end

  def existing_team
    @existing_team ||= Team.find_by(rid:)
  end

  def new_attrs
    {
      platform:,
      rid:,
      trial_expires_at: App.trial_period.from_now,
      response_mode:
    }.merge(update_attrs)
  end

  def update_attrs
    {
      name:,
      avatar_url:,
      api_key:,
      uninstalled_at: nil,
      uninstalled_by: nil,
      trial_expiry_notified_at: nil,
      team_size_notified_at: nil,
      onboarded_channels_at: nil,
      onboarded_emoji_at: nil
    }
  end

  def response_mode
    case platform
    when :slack then :adaptive
    end
  end
end
