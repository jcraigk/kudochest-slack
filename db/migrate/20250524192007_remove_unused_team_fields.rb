class RemoveUnusedTeamFields < ActiveRecord::Migration[7.1]
  def change
    remove_column :teams, :platform, :string
    remove_column :teams, :uninstalled_by, :string
    remove_column :teams, :gratis_subscription, :boolean
    remove_column :teams, :trial_expires_at, :datetime
    remove_column :teams, :stripe_customer_rid, :string
    remove_column :teams, :stripe_price_rid, :string
    remove_column :teams, :stripe_subscription_rid, :string
    remove_column :teams, :stripe_expires_at, :datetime
    remove_column :teams, :stripe_canceled_at, :datetime
    remove_column :teams, :stripe_declined_at, :datetime
    remove_column :teams, :trial_expiry_notified_at, :datetime
    remove_column :teams, :team_size_notified_at, :datetime
  end
end
