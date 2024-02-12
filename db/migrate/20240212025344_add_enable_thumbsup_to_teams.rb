class AddEnableThumbsupToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :enable_thumbsup, :boolean, default: true, null: false
  end
end
