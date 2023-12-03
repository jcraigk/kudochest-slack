class AddThrottledToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :throttled, :boolean, null: false, default: false
    Team.update_all(throttle_period: 'day')
  end
end
