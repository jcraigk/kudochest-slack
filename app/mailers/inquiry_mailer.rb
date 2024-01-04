class InquiryMailer < ApplicationMailer
  def created(inquiry)
    @inquiry = inquiry
    mail to: App.admin_email, subject: "Inquiry: #{@inquiry.subject.text}"
  end
end
