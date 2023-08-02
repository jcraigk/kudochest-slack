class CreateInquiries < ActiveRecord::Migration[7.0]
  def change
    create_table :inquiries do |t|
      t.references :user, optional: true
      t.string :subject, null: false
      t.text :body, null: false
      t.text :email
      t.timestamps
    end
  end
end
