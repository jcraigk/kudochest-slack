class AddPhoneToInquiries < ActiveRecord::Migration[7.1]
  def change
    add_column :inquiries, :phone, :string
  end
end
