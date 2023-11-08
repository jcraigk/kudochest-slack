class DropUsersAndPromoteProfiles < ActiveRecord::Migration[7.1]
  def change
    drop_table :users
    drop_table :authentications

    remove_column :profiles, :user_id, :bigint
    add_column :profiles, :email, :string
    add_column :profiles, :auth_token, :string
    add_column :profiles, :last_login_at, :datetime
    add_column :profiles, :theme, :string, null: false, default: 'light'
    add_column :profiles, :admin, :boolean, null: false, default: false

    change_column_default :profiles, :weekly_report, false
    change_column_default :teams, :weekly_report, false

    add_index :profiles, :email
    add_index :profiles, :auth_token

    rename_column :teams, :owner_user_id, :owner_profile_id
    rename_column :inquiries, :user_id, :profile_id
  end
end
