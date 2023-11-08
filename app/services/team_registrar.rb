class TeamRegistrar < Base::Service
  option :platform
  option :rid
  option :name
  option :avatar_url
  option :api_key
  option :owner_profile_rid

  def call
    team = create_or_update_team
    Slack::ChannelSyncService.call(team:)
    Slack::TeamSyncService.call(team:, first_run: true)
    assign_owner(team)
  end

  private

  def create_or_update_team
    return existing_team.tap { |team| team.update!(update_attrs) } if existing_team
    Team.create!(new_attrs)
  end

  def existing_team
    @existing_team ||= Team.find_by(rid:)
  end

  def assign_owner(team)
    team.update!(owner: Profile.find_by(rid: owner_profile_rid))
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
      uninstalled_by: nil
    }
  end

  def response_mode
    case platform
    when :slack then :adaptive
    end
  end
end
