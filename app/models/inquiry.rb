class Inquiry < ApplicationRecord
  belongs_to :profile, optional: true

  enumerize :subject,
            in: %w[general support bug feature],
            default: 'general'

  validates :body, presence: true

  after_create_commit :send_admin_email

  private

  def send_admin_email
    InquiryMailer.created(self).deliver_later
  end
end
