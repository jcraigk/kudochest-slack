class AddOnboardingColsToTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :teams, :onboarded_channels_at, :datetime
    add_column :teams, :onboarded_emoji_at, :datetime
  end
end
