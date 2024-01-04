class TeamPolicy < ApplicationPolicy
  def index?
    profile.admin?
  end

  def stripe_checkout_start?
    profile.admin?
  end

  def stripe_cancel?
    profile.admin?
  end

  def edit?
    profile.admin?
  end

  def update?
    profile.admin?
  end

  def reset_stats?
    profile.admin?
  end

  def uninstall?
    profile.admin?
  end

  def join_all_channels?
    profile.admin?
  end

  # def join_specific_channels?
  #   profile.admin?
  # end

  def skip_join_channels?
    profile.admin?
  end

  def export_data?
    profile.admin?
  end

  def confirm_emoji_added?
    profile.admin?
  end

  def skip_emoji?
    profile.admin?
  end
end
