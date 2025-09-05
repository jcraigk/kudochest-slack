class AddUpdatedAtIndexToChannels < ActiveRecord::Migration[8.0]
  def change
    add_index :channels, :updated_at, name: "index_channels_on_updated_at"
  end
end
