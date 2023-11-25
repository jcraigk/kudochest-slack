class RemoveTokenCols < ActiveRecord::Migration[7.1]
  def change
    rename_column :profiles, :infinite_tokens, :throttle_exempt
    remove_column :profiles, :tokens, :integer

    remove_column :teams, :throttle_tips, :boolean
    remove_column :teams, :token_max, :integer
    remove_column :teams, :token_day, :integer
    remove_column :teams, :notify_tokens, :boolean
    remove_column :teams, :next_tokens_at, :datetime
    remove_column :teams, :action_hour, :datetime
    rename_column :teams, :token_frequency, :throttle_period
    rename_column :teams, :token_quantity, :throttle_quantity
  end
end
