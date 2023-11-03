class AddSubscriptionColsToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :gratis_subscription, :boolean, null: false, default: false
    add_column :teams, :trial_expires_at, :datetime
    add_column :teams, :stripe_customer_rid, :string
    add_column :teams, :stripe_price_rid, :string
    add_column :teams, :stripe_subscription_rid, :string
    add_column :teams, :stripe_expires_at, :datetime
    add_column :teams, :stripe_canceled_at, :datetime
    add_column :teams, :stripe_declined_at, :datetime
    add_column :teams, :trial_expiry_notified_at, :datetime
    add_column :teams, :team_size_notified_at, :datetime

    remove_column :teams, :active, :boolean, null: false, default: false
    remove_column :teams, :installed, :boolean, null: false, default: false
    add_column :teams, :uninstalled_at, :datetime
    add_column :teams, :uninstalled_by, :string

    add_index :teams, :stripe_customer_rid
    add_index :teams, :stripe_price_rid
    add_index :teams, :stripe_subscription_rid

    remove_column :teams, :app_subteam_rid, :string
  end
end
