class Inquiry < ApplicationRecord
  extend Enumerize

  belongs_to :user, optional: true

  enumerize :subject,
            in: %w[general support bug feature],
            default: 'general'

  validates :body, presence: true

  after_create_commit :send_admin_email

  private

  def send_admin_email
    AdminMailer.inquiry_created(self).deliver_later
  end
end
