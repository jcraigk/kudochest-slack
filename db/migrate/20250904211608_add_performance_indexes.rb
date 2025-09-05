class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Index for tip queries by date and quantity
    add_index :tips, [:created_at, :quantity], name: "index_tips_on_created_at_and_quantity"
    
    # Index for active profiles sorted by points received
    add_index :profiles, [:points_received, :deleted], name: "index_profiles_on_points_received_and_deleted"
    
    # Index for active profiles sorted by points sent
    add_index :profiles, [:points_sent, :deleted], name: "index_profiles_on_points_sent_and_deleted"
    
    # Index for active profiles sorted by balance
    add_index :profiles, [:balance, :deleted], name: "index_profiles_on_balance_and_deleted"
    
    # Index for tips by profile and date for throttling queries
    add_index :tips, [:from_profile_id, :created_at], name: "index_tips_on_from_profile_id_and_created_at"
    
    # Index for subteam memberships (reverse lookup)
    add_index :subteam_memberships, :subteam_id, name: "index_subteam_memberships_on_subteam_id" if !index_exists?(:subteam_memberships, :subteam_id)
  end
end
