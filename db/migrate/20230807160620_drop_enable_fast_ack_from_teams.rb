class DropEnableFastAckFromTeams < ActiveRecord::Migration[7.0]
  def change
    remove_column :teams, :enable_fast_ack, :boolean, null: false, default: true
  end
end
