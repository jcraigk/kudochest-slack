class AddInitialMemberCountToChannels < ActiveRecord::Migration[7.0]
  def change
    add_column :channels, :initial_member_count, :integer, default: 0, null: false
  end
end
