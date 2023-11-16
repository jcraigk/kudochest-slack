class SimplifyProfileTokenCols < ActiveRecord::Migration[7.1]
  def change
    remove_column :profiles, :tokens_forfeited, :integer, default: 0, null: false
    rename_column :profiles, :tokens_accrued, :tokens
    change_column_default :profiles, :tokens, from: nil, to: 0

    rename_column :teams, :week_start_day, :token_day
    add_column :teams, :next_tokens_at, :datetime
    remove_column :teams, :tokens_disbursed_at, :datetime
  end
end
