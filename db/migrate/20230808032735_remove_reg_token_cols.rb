class RemoveRegTokenCols < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :reg_token, :string, null: false
    remove_column :profiles, :reg_token, :string, null: false
  end
end
