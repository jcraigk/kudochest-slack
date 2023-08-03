class Base::TeamSyncService < Base::Service
  option :team
  option :first_run, default: proc { false }

  def call
    sync_team_data
  end

  private

  def sync_team_data
    sync_member_count

    sync_profiles
    sync_subteams
    handle_token_dispersal if first_run
  end

  def sync_member_count
    team.member_count = active_member_count
    team.save!
  end

  def active_member_count
    remote_team_members.count { |member| active?(member) }
  end

  def handle_token_dispersal
    TokenDispersalService.call(team:, notify: false)
  end

  def sync_subteams
    SubteamSyncWorker.perform_async(team.rid)
  end

  def sync_profiles
    synced_profile_ids =
      remote_team_members.each_with_object([]) do |member, profile_ids|
        next unless app_bot?(member) || active?(member)
        profile = create_or_update_profile(member)
        auto_associate_user(profile)
        profile_ids << profile.id
      end

    # Delete local profiles that were not found remotely
    team.profiles.active.where.not(id: synced_profile_ids).each do |profile|
      profile.update(deleted: true)
    end
  end

  def auto_associate_user(profile)
    return if profile.user.present?
    return if (user = Authentication.find_by(uid: profile.rid)&.user).blank?
    profile.update!(user:)
  end

  def remote_team_members
    @remote_team_members ||= fetch_team_members
  end

  def create_or_update_profile(member)
    member = member[:user] if team.platform.discord?

    base_attrs = base_attributes(member)
    sync_attrs = syncable_attributes(member).merge(deleted: false)
    profile = create_or_update(base_attrs, sync_attrs)

    team.update(app_profile_rid: profile.rid) if app_bot?(member)

    profile
  end

  def create_or_update(base_attrs, sync_attrs)
    profile = Profile.find_by(base_attrs)

    if profile
      profile.update(sync_attrs)
    else
      profile = Profile.create!(base_attrs.merge(sync_attrs))
    end

    profile
  end
end
