class Base::TeamSyncService < Base::Service
  option :team
  option :first_run, default: proc { false }

  def call
    sync_team_data
  end

  private

  def sync_team_data
    sync_profiles
    sync_subteams

    return unless first_run
    return unless App.enable_email

    OnboardingMailer.welcome(team).deliver_later
  end

  def sync_subteams
    SubteamSyncWorker.perform_async(team.rid)
  end

  def sync_profiles
    synced_profile_ids = []
    active_member_count = 0
    batch_size = 100

    remote_team_members.each_slice(batch_size) do |member_batch|
      Profile.transaction do
        member_batch.each do |member|
          active_member_count += 1 if active?(member)
          next unless app_bot?(member) || active?(member)
          profile = create_or_update_profile(member)
          synced_profile_ids << profile.id
        end
      end
    end

    team.update!(member_count: active_member_count)

    # Delete local profiles that were not found remotely
    return if (profiles = team.profiles.active.where.not(id: synced_profile_ids)).blank?
    profiles.update_all(deleted: true) # rubocop:disable Rails/SkipsModelValidations
    refresh_leaderboards
  end

  def refresh_leaderboards
    [ true, false ].product([ true, false ]) do |giving_board, jab_board|
      LeaderboardRefreshWorker.perform_async(team.id, giving_board, jab_board)
    end
  end

  def remote_team_members
    @remote_team_members ||= fetch_team_members
  end

  def create_or_update_profile(member)
    base_attrs = base_attributes(member)
    sync_attrs = syncable_attributes(member).merge(deleted: false)
    profile = create_or_update(base_attrs, sync_attrs)
    team.update(app_profile_rid: profile.rid) if app_bot?(member)
    profile
  end

  def create_or_update(base_attrs, sync_attrs)
    profile = Profile.find_by(base_attrs)

    if profile
      profile.update!(sync_attrs)
    else
      profile = Profile.create!(base_attrs.merge(sync_attrs))
    end

    profile
  end
end
