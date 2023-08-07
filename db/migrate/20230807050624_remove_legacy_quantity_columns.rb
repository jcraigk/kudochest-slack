class RemoveLegacyQuantityColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :teams, :tip_increment, :decimal, precision: 4, scale: 2
    remove_column :teams, :emoji_quantity, :decimal, precision: 4, scale: 2
  end
end
