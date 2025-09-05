class AddLeaderboardCompositeIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :profiles, 
              [:team_id, :deleted, :points_received, :last_tip_received_at, :display_name], 
              name: "idx_leaderboard_points_received",
              where: "deleted = false AND last_tip_received_at IS NOT NULL"
    
    add_index :profiles, 
              [:team_id, :deleted, :points_sent, :last_tip_sent_at, :display_name], 
              name: "idx_leaderboard_points_sent",
              where: "deleted = false AND last_tip_sent_at IS NOT NULL"
    
    add_index :profiles, 
              [:team_id, :deleted, :balance, :last_tip_received_at, :display_name], 
              name: "idx_leaderboard_balance",
              where: "deleted = false AND last_tip_received_at IS NOT NULL"
    
    add_index :profiles, 
              [:team_id, :deleted, :jabs_received, :last_tip_received_at, :display_name], 
              name: "idx_leaderboard_jabs_received",
              where: "deleted = false AND last_tip_received_at IS NOT NULL"
    
    add_index :profiles, 
              [:team_id, :deleted, :jabs_sent, :last_tip_sent_at, :display_name], 
              name: "idx_leaderboard_jabs_sent",
              where: "deleted = false AND last_tip_sent_at IS NOT NULL"
  end
end
