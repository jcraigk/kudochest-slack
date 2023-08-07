class ChangeDecimalColumnsToInteger < ActiveRecord::Migration[7.0]
  def change
    change_column :profiles, :tokens_forfeited, :integer, default: 0, null: false
    change_column :profiles, :points_received, :integer, default: 0, null: false
    change_column :profiles, :points_sent, :integer, default: 0, null: false
    change_column :profiles, :jabs_sent, :integer, default: 0, null: false
    change_column :profiles, :jabs_received, :integer, default: 0, null: false
    change_column :profiles, :balance, :integer, default: 0, null: false

    change_column :teams, :points_sent, :integer, default: 0, null: false
    change_column :teams, :jabs_sent, :integer, default: 0, null: false
    change_column :teams, :balance, :integer, default: 0, null: false

    change_column :tips, :quantity, :integer, default: 0, null: false
  end
end
