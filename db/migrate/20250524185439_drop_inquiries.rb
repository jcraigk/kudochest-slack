class DropInquiries < ActiveRecord::Migration[7.1]
  def change
    drop_table :inquiries
  end
end
