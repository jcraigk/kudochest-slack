class ImproveAdminSchema < ActiveRecord::Migration[7.1]
  def change
    rename_column :profiles, :admin, :superuser
    add_column :profiles, :admin, :boolean, null: false, default: false
    Team.find_each do |team|
      team.profiles.find(team.owner_profile_id).update(admin: true)
    end
    remove_column :teams, :owner_profile_id, :integer
  end
end
