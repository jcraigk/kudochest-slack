class AddDefaultPointQuantitiesToTeams < ActiveRecord::Migration[8.0]
  def change
    add_column :teams, :default_inline_point_quantity, :integer, null: false, default: 1
    add_column :teams, :default_reaction_point_quantity, :integer, null: false, default: 1
  end
end
